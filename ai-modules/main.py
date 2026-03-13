#!/usr/bin/env python3
"""
FIVEGUARD AI SERVICE
AI Destekli FiveM Anti-Cheat Sistemi - Ana AI Servisi

Bu servis aşağıdaki AI modüllerini içerir:
- Screenshot analizi ve menü tespiti
- Davranış analizi ve anomali tespiti
- Sahne analizi ve nesne tespiti
- Makine öğrenmesi tabanlı hile tespiti
"""

import asyncio
import os
import sys
import signal
import logging
from pathlib import Path
from typing import Dict, Any, Optional
import uvicorn
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import redis.asyncio as redis
from loguru import logger
import torch
import tensorflow as tf

# Add project root to path
sys.path.append(str(Path(__file__).parent))

# Import AI modules
from src.config.settings import Settings
from src.services.screenshot_analyzer import ScreenshotAnalyzer
from src.services.behavior_analyzer import BehaviorAnalyzer
from src.services.scene_analyzer import SceneAnalyzer
from src.services.anomaly_detector import AnomalyDetector
from src.services.model_manager import ModelManager
from src.utils.logger_config import setup_logger
from src.utils.metrics import MetricsCollector
from src.middleware.auth import verify_api_key
from src.middleware.rate_limit import RateLimiter

# Global variables
settings = Settings()
redis_client: Optional[redis.Redis] = None
model_manager: Optional[ModelManager] = None
screenshot_analyzer: Optional[ScreenshotAnalyzer] = None
behavior_analyzer: Optional[BehaviorAnalyzer] = None
scene_analyzer: Optional[SceneAnalyzer] = None
anomaly_detector: Optional[AnomalyDetector] = None
metrics_collector: Optional[MetricsCollector] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    await startup_event()
    yield
    # Shutdown
    await shutdown_event()

# Initialize FastAPI app
app = FastAPI(
    title="Fiveguard AI Service",
    description="AI Destekli FiveM Anti-Cheat Sistemi",
    version="1.0.0",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(GZipMiddleware, minimum_size=1000)

# Setup logging
setup_logger(settings.LOG_LEVEL, settings.LOG_FILE)

async def startup_event():
    """Initialize services on startup"""
    global redis_client, model_manager, screenshot_analyzer, behavior_analyzer
    global scene_analyzer, anomaly_detector, metrics_collector
    
    try:
        logger.info("🚀 Fiveguard AI Service başlatılıyor...")
        
        # Initialize Redis connection
        redis_client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            password=settings.REDIS_PASSWORD,
            db=settings.REDIS_DB,
            decode_responses=True
        )
        await redis_client.ping()
        logger.info("✅ Redis bağlantısı kuruldu")
        
        # Check GPU availability
        if torch.cuda.is_available():
            logger.info(f"🎮 GPU kullanılabilir: {torch.cuda.get_device_name(0)}")
            logger.info(f"🎮 CUDA Version: {torch.version.cuda}")
        else:
            logger.warning("⚠️ GPU bulunamadı, CPU kullanılacak")
        
        # Check TensorFlow GPU
        if tf.config.list_physical_devices('GPU'):
            logger.info("🎮 TensorFlow GPU desteği aktif")
        else:
            logger.warning("⚠️ TensorFlow GPU desteği bulunamadı")
        
        # Initialize model manager
        model_manager = ModelManager(settings)
        await model_manager.initialize()
        logger.info("🧠 Model Manager başlatıldı")
        
        # Initialize AI services
        screenshot_analyzer = ScreenshotAnalyzer(model_manager, redis_client)
        await screenshot_analyzer.initialize()
        logger.info("📸 Screenshot Analyzer başlatıldı")
        
        behavior_analyzer = BehaviorAnalyzer(model_manager, redis_client)
        await behavior_analyzer.initialize()
        logger.info("🎯 Behavior Analyzer başlatıldı")
        
        scene_analyzer = SceneAnalyzer(model_manager, redis_client)
        await scene_analyzer.initialize()
        logger.info("🌍 Scene Analyzer başlatıldı")
        
        anomaly_detector = AnomalyDetector(model_manager, redis_client)
        await anomaly_detector.initialize()
        logger.info("🔍 Anomaly Detector başlatıldı")
        
        # Initialize metrics collector
        metrics_collector = MetricsCollector(redis_client)
        await metrics_collector.initialize()
        logger.info("📊 Metrics Collector başlatıldı")
        
        # Load pre-trained models
        await model_manager.load_models()
        logger.info("🤖 AI modelleri yüklendi")
        
        logger.info("🎉 Fiveguard AI Service başarıyla başlatıldı!")
        
    except Exception as e:
        logger.error(f"❌ Başlatma hatası: {e}")
        raise

async def shutdown_event():
    """Cleanup on shutdown"""
    global redis_client, model_manager
    
    try:
        logger.info("🛑 Fiveguard AI Service kapatılıyor...")
        
        # Save models and cleanup
        if model_manager:
            await model_manager.cleanup()
            logger.info("🧠 Model Manager temizlendi")
        
        # Close Redis connection
        if redis_client:
            await redis_client.close()
            logger.info("✅ Redis bağlantısı kapatıldı")
        
        logger.info("👋 Fiveguard AI Service başarıyla kapatıldı")
        
    except Exception as e:
        logger.error(f"❌ Kapatma hatası: {e}")

# =============================================
# HEALTH CHECK ENDPOINTS
# =============================================

@app.get("/health")
async def health_check():
    """System health check"""
    try:
        # Check Redis
        redis_status = "healthy"
        try:
            await redis_client.ping()
        except:
            redis_status = "unhealthy"
        
        # Check GPU
        gpu_status = "available" if torch.cuda.is_available() else "unavailable"
        
        # Check models
        models_status = "loaded" if model_manager and model_manager.models_loaded else "not_loaded"
        
        # Memory usage
        if torch.cuda.is_available():
            gpu_memory = {
                "allocated": torch.cuda.memory_allocated() / 1024**3,  # GB
                "cached": torch.cuda.memory_reserved() / 1024**3,      # GB
                "total": torch.cuda.get_device_properties(0).total_memory / 1024**3  # GB
            }
        else:
            gpu_memory = None
        
        health_data = {
            "status": "healthy",
            "timestamp": asyncio.get_event_loop().time(),
            "version": "1.0.0",
            "services": {
                "redis": redis_status,
                "gpu": gpu_status,
                "models": models_status
            },
            "memory": {
                "gpu": gpu_memory
            },
            "models_info": await model_manager.get_models_info() if model_manager else {}
        }
        
        # Determine overall status
        overall_healthy = all([
            redis_status == "healthy",
            models_status == "loaded"
        ])
        
        health_data["status"] = "healthy" if overall_healthy else "degraded"
        
        return JSONResponse(
            content=health_data,
            status_code=200 if overall_healthy else 503
        )
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            content={
                "status": "unhealthy",
                "error": str(e),
                "timestamp": asyncio.get_event_loop().time()
            },
            status_code=503
        )

@app.get("/metrics")
async def get_metrics():
    """Get system metrics"""
    try:
        if not metrics_collector:
            raise HTTPException(status_code=503, detail="Metrics collector not initialized")
        
        metrics = await metrics_collector.get_metrics()
        return JSONResponse(content=metrics)
        
    except Exception as e:
        logger.error(f"Metrics collection failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# SCREENSHOT ANALYSIS ENDPOINTS
# =============================================

@app.post("/api/analyze/screenshot")
async def analyze_screenshot(
    request: Dict[str, Any],
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Analyze screenshot for cheat detection"""
    try:
        if not screenshot_analyzer:
            raise HTTPException(status_code=503, detail="Screenshot analyzer not initialized")
        
        # Validate request
        required_fields = ["image_data", "player_id"]
        for field in required_fields:
            if field not in request:
                raise HTTPException(status_code=400, detail=f"Missing required field: {field}")
        
        # Analyze screenshot
        result = await screenshot_analyzer.analyze(
            image_data=request["image_data"],
            player_id=request["player_id"],
            metadata=request.get("metadata", {})
        )
        
        # Update metrics in background
        background_tasks.add_task(
            metrics_collector.update_analysis_metrics,
            "screenshot",
            result.get("confidence", 0),
            result.get("processing_time", 0)
        )
        
        return JSONResponse(content=result)
        
    except Exception as e:
        logger.error(f"Screenshot analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/analyze/screenshot/batch")
async def analyze_screenshots_batch(
    request: Dict[str, Any],
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Analyze multiple screenshots in batch"""
    try:
        if not screenshot_analyzer:
            raise HTTPException(status_code=503, detail="Screenshot analyzer not initialized")
        
        screenshots = request.get("screenshots", [])
        if not screenshots:
            raise HTTPException(status_code=400, detail="No screenshots provided")
        
        results = await screenshot_analyzer.analyze_batch(screenshots)
        
        # Update metrics
        background_tasks.add_task(
            metrics_collector.update_batch_metrics,
            "screenshot",
            len(screenshots),
            sum(r.get("processing_time", 0) for r in results)
        )
        
        return JSONResponse(content={"results": results})
        
    except Exception as e:
        logger.error(f"Batch screenshot analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# BEHAVIOR ANALYSIS ENDPOINTS
# =============================================

@app.post("/api/analyze/behavior")
async def analyze_behavior(
    request: Dict[str, Any],
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Analyze player behavior for anomalies"""
    try:
        if not behavior_analyzer:
            raise HTTPException(status_code=503, detail="Behavior analyzer not initialized")
        
        # Validate request
        required_fields = ["player_id", "behavior_data"]
        for field in required_fields:
            if field not in request:
                raise HTTPException(status_code=400, detail=f"Missing required field: {field}")
        
        result = await behavior_analyzer.analyze(
            player_id=request["player_id"],
            behavior_data=request["behavior_data"],
            historical_data=request.get("historical_data", [])
        )
        
        # Update metrics
        background_tasks.add_task(
            metrics_collector.update_analysis_metrics,
            "behavior",
            result.get("anomaly_score", 0),
            result.get("processing_time", 0)
        )
        
        return JSONResponse(content=result)
        
    except Exception as e:
        logger.error(f"Behavior analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/analyze/behavior/pattern")
async def analyze_behavior_pattern(
    request: Dict[str, Any],
    api_key: str = Depends(verify_api_key)
):
    """Analyze long-term behavior patterns"""
    try:
        if not behavior_analyzer:
            raise HTTPException(status_code=503, detail="Behavior analyzer not initialized")
        
        result = await behavior_analyzer.analyze_pattern(
            player_id=request["player_id"],
            time_window=request.get("time_window", 3600),  # 1 hour default
            pattern_types=request.get("pattern_types", ["movement", "combat", "interaction"])
        )
        
        return JSONResponse(content=result)
        
    except Exception as e:
        logger.error(f"Behavior pattern analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# SCENE ANALYSIS ENDPOINTS
# =============================================

@app.post("/api/analyze/scene")
async def analyze_scene(
    request: Dict[str, Any],
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Analyze game scene for suspicious objects/activities"""
    try:
        if not scene_analyzer:
            raise HTTPException(status_code=503, detail="Scene analyzer not initialized")
        
        result = await scene_analyzer.analyze(
            scene_data=request["scene_data"],
            player_id=request["player_id"],
            context=request.get("context", {})
        )
        
        # Update metrics
        background_tasks.add_task(
            metrics_collector.update_analysis_metrics,
            "scene",
            result.get("suspicion_level", 0),
            result.get("processing_time", 0)
        )
        
        return JSONResponse(content=result)
        
    except Exception as e:
        logger.error(f"Scene analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# ANOMALY DETECTION ENDPOINTS
# =============================================

@app.post("/api/detect/anomaly")
async def detect_anomaly(
    request: Dict[str, Any],
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Detect anomalies in player data"""
    try:
        if not anomaly_detector:
            raise HTTPException(status_code=503, detail="Anomaly detector not initialized")
        
        result = await anomaly_detector.detect(
            data=request["data"],
            player_id=request["player_id"],
            detection_type=request.get("detection_type", "general")
        )
        
        # Update metrics
        background_tasks.add_task(
            metrics_collector.update_detection_metrics,
            result.get("anomaly_type", "unknown"),
            result.get("confidence", 0)
        )
        
        return JSONResponse(content=result)
        
    except Exception as e:
        logger.error(f"Anomaly detection failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/detect/anomaly/realtime")
async def detect_realtime_anomaly(
    request: Dict[str, Any],
    api_key: str = Depends(verify_api_key)
):
    """Real-time anomaly detection"""
    try:
        if not anomaly_detector:
            raise HTTPException(status_code=503, detail="Anomaly detector not initialized")
        
        result = await anomaly_detector.detect_realtime(
            stream_data=request["stream_data"],
            player_id=request["player_id"]
        )
        
        return JSONResponse(content=result)
        
    except Exception as e:
        logger.error(f"Real-time anomaly detection failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# MODEL MANAGEMENT ENDPOINTS
# =============================================

@app.get("/api/models/status")
async def get_models_status(api_key: str = Depends(verify_api_key)):
    """Get status of all AI models"""
    try:
        if not model_manager:
            raise HTTPException(status_code=503, detail="Model manager not initialized")
        
        status = await model_manager.get_status()
        return JSONResponse(content=status)
        
    except Exception as e:
        logger.error(f"Model status check failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/models/reload")
async def reload_models(
    request: Dict[str, Any],
    api_key: str = Depends(verify_api_key)
):
    """Reload specific models"""
    try:
        if not model_manager:
            raise HTTPException(status_code=503, detail="Model manager not initialized")
        
        model_names = request.get("models", [])
        results = await model_manager.reload_models(model_names)
        
        return JSONResponse(content={"results": results})
        
    except Exception as e:
        logger.error(f"Model reload failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/models/update")
async def update_models(
    request: Dict[str, Any],
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Update models with new training data"""
    try:
        if not model_manager:
            raise HTTPException(status_code=503, detail="Model manager not initialized")
        
        # Start model update in background
        background_tasks.add_task(
            model_manager.update_models,
            request.get("training_data", {}),
            request.get("model_configs", {})
        )
        
        return JSONResponse(content={"message": "Model update started"})
        
    except Exception as e:
        logger.error(f"Model update failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# TRAINING ENDPOINTS
# =============================================

@app.post("/api/train/feedback")
async def submit_training_feedback(
    request: Dict[str, Any],
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Submit feedback for model training"""
    try:
        if not model_manager:
            raise HTTPException(status_code=503, detail="Model manager not initialized")
        
        # Process feedback in background
        background_tasks.add_task(
            model_manager.process_feedback,
            request["feedback_data"],
            request["model_type"]
        )
        
        return JSONResponse(content={"message": "Feedback submitted successfully"})
        
    except Exception as e:
        logger.error(f"Feedback submission failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================
# SIGNAL HANDLERS
# =============================================

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    logger.info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

# =============================================
# MAIN ENTRY POINT
# =============================================

if __name__ == "__main__":
    # Print startup banner
    print("""
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ███████╗██╗██╗   ██╗███████╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ║
║   ██╔════╝██║██║   ██║██╔════╝██╔════╝ ██║   ██║██╔══██╗██╔══██╗║
║   █████╗  ██║██║   ██║█████╗  ██║  ███╗██║   ██║███████║██████╔╝║
║   ██╔══╝  ██║╚██╗ ██╔╝██╔══╝  ██║   ██║██║   ██║██╔══██║██╔══██╗║
║   ██║     ██║ ╚████╔╝ ███████╗╚██████╔╝╚██████╔╝██║  ██║██║  ██║║
║   ╚═╝     ╚═╝  ╚═══╝  ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝║
║                                                               ║
║                    AI SERVICE v1.0.0                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
    """)
    
    # Run the server
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        workers=1,  # Single worker for GPU memory management
        log_level=settings.LOG_LEVEL.lower(),
        access_log=settings.DEBUG
    )
