// FIVEGUARD API SERVER
// AI Destekli FiveM Anti-Cheat API

require('dotenv').config();
require('express-async-errors');

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');
const { createServer } = require('http');
const { Server } = require('socket.io');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

// Internal modules
const config = require('./src/config/config');
const logger = require('./src/utils/logger');
const database = require('./src/config/database');
const redis = require('./src/config/redis');
const errorHandler = require('./src/middleware/errorHandler');
const authMiddleware = require('./src/middleware/auth');

// Routes
const authRoutes = require('./src/routes/auth');
const dashboardRoutes = require('./src/routes/dashboard');
const playersRoutes = require('./src/routes/players');
const detectionsRoutes = require('./src/routes/detections');
const bansRoutes = require('./src/routes/bans');
const logsRoutes = require('./src/routes/logs');
const configRoutes = require('./src/routes/config');
const aiRoutes = require('./src/routes/ai');
const webhookRoutes = require('./src/routes/webhooks');
const licenseRoutes = require('./src/routes/license');

// Services
const socketService = require('./src/services/socketService');
const cronService = require('./src/services/cronService');
const aiService = require('./src/services/aiService');

// Initialize Express app
const app = express();
const server = createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ['websocket', 'polling']
});

// =============================================
// MIDDLEWARE SETUP
// =============================================

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      scriptSrc: ["'self'"],
      connectSrc: ["'self'", "ws:", "wss:"]
    }
  },
  crossOriginEmbedderPolicy: false
}));

// CORS configuration
app.use(cors({
  origin: function (origin, callback) {
    const allowedOrigins = [
      process.env.FRONTEND_URL || 'http://localhost:3000',
      'http://localhost:3000',
      'http://127.0.0.1:3000'
    ];
    
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('CORS policy violation'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 100 : 1000, // requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for health checks and internal requests
    return req.path === '/health' || req.path === '/api/health';
  }
});

app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// Compression middleware
app.use(compression());

// Logging middleware
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined', {
    stream: {
      write: (message) => logger.info(message.trim())
    }
  }));
}

// Request ID middleware
app.use((req, res, next) => {
  req.id = require('uuid').v4();
  res.setHeader('X-Request-ID', req.id);
  next();
});

// =============================================
// SWAGGER DOCUMENTATION
// =============================================

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Fiveguard API',
      version: '1.0.0',
      description: 'AI Destekli FiveM Anti-Cheat API Documentation',
      contact: {
        name: 'Fiveguard Team',
        email: 'support@fiveguard.com',
        url: 'https://fiveguard.com'
      },
      license: {
        name: 'Private License',
        url: 'https://fiveguard.com/license'
      }
    },
    servers: [
      {
        url: process.env.API_URL || 'http://localhost:3001',
        description: 'Development server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ]
  },
  apis: ['./src/routes/*.js', './src/models/*.js']
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Fiveguard API Documentation',
  customfavIcon: '/favicon.ico'
}));

// Swagger JSON endpoint
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// =============================================
// HEALTH CHECK ENDPOINTS
// =============================================

app.get('/health', async (req, res) => {
  try {
    // Check database connection
    const dbStatus = await database.testConnection();
    
    // Check Redis connection
    const redisStatus = await redis.ping();
    
    // Check AI service
    const aiStatus = await aiService.healthCheck();
    
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: process.env.npm_package_version || '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      services: {
        database: dbStatus ? 'healthy' : 'unhealthy',
        redis: redisStatus === 'PONG' ? 'healthy' : 'unhealthy',
        ai: aiStatus ? 'healthy' : 'unhealthy'
      },
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB'
      },
      cpu: {
        usage: process.cpuUsage()
      }
    };
    
    // Determine overall status
    const allServicesHealthy = Object.values(health.services).every(status => status === 'healthy');
    health.status = allServicesHealthy ? 'healthy' : 'degraded';
    
    res.status(allServicesHealthy ? 200 : 503).json(health);
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

app.get('/api/health', (req, res) => res.redirect('/health'));

// =============================================
// API ROUTES
// =============================================

// Public routes
app.use('/api/auth', authRoutes);
app.use('/api/license', licenseRoutes);
app.use('/api/webhooks', webhookRoutes);

// Protected routes
app.use('/api/dashboard', authMiddleware, dashboardRoutes);
app.use('/api/players', authMiddleware, playersRoutes);
app.use('/api/detections', authMiddleware, detectionsRoutes);
app.use('/api/bans', authMiddleware, bansRoutes);
app.use('/api/logs', authMiddleware, logsRoutes);
app.use('/api/config', authMiddleware, configRoutes);
app.use('/api/ai', authMiddleware, aiRoutes);

// =============================================
// STATIC FILES
// =============================================

// Serve uploaded files
app.use('/uploads', express.static('uploads'));
app.use('/screenshots', authMiddleware, express.static('screenshots'));

// Serve frontend build (if exists)
if (process.env.NODE_ENV === 'production') {
  app.use(express.static('../web-panel/build'));
  
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../web-panel/build/index.html'));
  });
}

// =============================================
// ERROR HANDLING
// =============================================

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.originalUrl}`,
    timestamp: new Date().toISOString(),
    requestId: req.id
  });
});

// Global error handler
app.use(errorHandler);

// =============================================
// SOCKET.IO SETUP
// =============================================

// Initialize socket service
socketService.initialize(io);

// Socket.IO connection handling
io.on('connection', (socket) => {
  logger.info(`Socket connected: ${socket.id}`);
  
  // Handle authentication
  socket.on('authenticate', async (token) => {
    try {
      const user = await authMiddleware.verifySocketToken(token);
      socket.userId = user.id;
      socket.licenseId = user.licenseId;
      socket.join(`license_${user.licenseId}`);
      
      socket.emit('authenticated', { success: true, user: user });
      logger.info(`Socket authenticated: ${socket.id} (User: ${user.id})`);
    } catch (error) {
      socket.emit('authentication_error', { error: error.message });
      socket.disconnect();
    }
  });
  
  // Handle real-time data requests
  socket.on('subscribe_dashboard', () => {
    if (socket.licenseId) {
      socket.join(`dashboard_${socket.licenseId}`);
    }
  });
  
  socket.on('subscribe_detections', () => {
    if (socket.licenseId) {
      socket.join(`detections_${socket.licenseId}`);
    }
  });
  
  socket.on('subscribe_players', () => {
    if (socket.licenseId) {
      socket.join(`players_${socket.licenseId}`);
    }
  });
  
  // Handle disconnection
  socket.on('disconnect', (reason) => {
    logger.info(`Socket disconnected: ${socket.id} (Reason: ${reason})`);
  });
  
  // Handle errors
  socket.on('error', (error) => {
    logger.error(`Socket error: ${socket.id}`, error);
  });
});

// =============================================
// GRACEFUL SHUTDOWN
// =============================================

const gracefulShutdown = async (signal) => {
  logger.info(`Received ${signal}. Starting graceful shutdown...`);
  
  // Stop accepting new connections
  server.close(async () => {
    logger.info('HTTP server closed');
    
    try {
      // Close database connections
      await database.close();
      logger.info('Database connections closed');
      
      // Close Redis connection
      await redis.quit();
      logger.info('Redis connection closed');
      
      // Stop cron jobs
      cronService.stop();
      logger.info('Cron jobs stopped');
      
      // Close Socket.IO
      io.close();
      logger.info('Socket.IO closed');
      
      logger.info('Graceful shutdown completed');
      process.exit(0);
    } catch (error) {
      logger.error('Error during graceful shutdown:', error);
      process.exit(1);
    }
  });
  
  // Force shutdown after 30 seconds
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 30000);
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  gracefulShutdown('UNCAUGHT_EXCEPTION');
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  gracefulShutdown('UNHANDLED_REJECTION');
});

// =============================================
// SERVER STARTUP
// =============================================

const startServer = async () => {
  try {
    // Initialize database
    await database.initialize();
    logger.info('Database initialized');
    
    // Initialize Redis
    await redis.connect();
    logger.info('Redis connected');
    
    // Initialize AI service
    await aiService.initialize();
    logger.info('AI service initialized');
    
    // Start cron jobs
    cronService.start();
    logger.info('Cron jobs started');
    
    // Start server
    const PORT = process.env.PORT || 3001;
    const HOST = process.env.HOST || '0.0.0.0';
    
    server.listen(PORT, HOST, () => {
      logger.info(`🚀 Fiveguard API Server started`);
      logger.info(`📡 Server running on http://${HOST}:${PORT}`);
      logger.info(`📚 API Documentation: http://${HOST}:${PORT}/api-docs`);
      logger.info(`🏥 Health Check: http://${HOST}:${PORT}/health`);
      logger.info(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
      logger.info(`🔧 Node.js Version: ${process.version}`);
      
      // Log startup banner
      console.log(`
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ███████╗██╗██╗   ██╗███████╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ║
║   ██╔════╝██║██║   ██║██╔════╝██╔════╝ ██║   ██║██╔══██╗██╔══██╗║
║   █████╗  ██║██║   ██║█████╗  ██║  ███╗██║   ██║███████║██████╔╝║
║   ██╔══╝  ██║╚██╗ ██╔╝██╔══╝  ██║   ██║██║   ██║██╔══██║██╔══██╗║
║   ██║     ██║ ╚████╔╝ ███████╗╚██████╔╝╚██████╔╝██║  ██║██║  ██║║
║   ╚═╝     ╚═╝  ╚═══╝  ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝║
║                                                               ║
║                 AI Destekli Anti-Cheat API                   ║
║                        v1.0.0                                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
      `);
    });
    
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
if (require.main === module) {
  startServer();
}

module.exports = { app, server, io };
