#!/usr/bin/env python3
"""
FIVEGUARD OCR DETECTOR SERVICE
Cheat menü tespiti için OCR ve görüntü analizi servisi
"""

import cv2
import numpy as np
import asyncio
import base64
import io
from typing import Dict, List, Tuple, Optional, Any
from PIL import Image, ImageEnhance, ImageFilter
import pytesseract
import easyocr
from loguru import logger
import re
import json
from datetime import datetime
import hashlib

# ML/AI imports
import torch
import torchvision.transforms as transforms
from transformers import pipeline
import tensorflow as tf

class OCRDetector:
    """OCR tabanlı cheat menü tespit sistemi"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
        # OCR engines
        self.tesseract_config = '--oem 3 --psm 6 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[](){}.,!@#$%^&*-_=+|\\:;"\'<>?/~`'
        self.easyocr_reader = None
        
        # AI models
        self.text_classifier = None
        self.image_classifier = None
        
        # Blacklists
        self.menu_keywords = self._load_menu_keywords()
        self.cheat_patterns = self._load_cheat_patterns()
        self.menu_signatures = self._load_menu_signatures()
        
        # Statistics
        self.stats = {
            'total_processed': 0,
            'detections': 0,
            'false_positives': 0,
            'processing_time': []
        }
        
        logger.info("OCR Detector initialized")
    
    async def initialize(self):
        """Servisi başlat"""
        try:
            # EasyOCR reader'ı başlat
            self.easyocr_reader = easyocr.Reader(['en', 'tr'], gpu=torch.cuda.is_available())
            logger.info("EasyOCR reader initialized")
            
            # AI modellerini yükle
            await self._load_ai_models()
            
            logger.info("OCR Detector fully initialized")
            
        except Exception as e:
            logger.error(f"OCR Detector initialization failed: {e}")
            raise
    
    async def analyze_screenshot(self, image_data: str, player_id: str, metadata: Dict = None) -> Dict[str, Any]:
        """Screenshot'ı analiz et"""
        start_time = datetime.now()
        
        try:
            # Base64'ten görüntüyü decode et
            image = self._decode_image(image_data)
            if image is None:
                return self._create_result(False, 0, "Invalid image data")
            
            # Görüntüyü ön işle
            processed_image = await self._preprocess_image(image)
            
            # OCR analizi
            ocr_results = await self._perform_ocr_analysis(processed_image)
            
            # AI görüntü analizi
            ai_results = await self._perform_ai_analysis(processed_image)
            
            # Sonuçları birleştir ve değerlendir
            final_result = await self._evaluate_results(ocr_results, ai_results, metadata)
            
            # İstatistikleri güncelle
            processing_time = (datetime.now() - start_time).total_seconds()
            self._update_stats(final_result['detected'], processing_time)
            
            # Sonucu kaydet
            await self._save_analysis_result(player_id, final_result, image_data)
            
            return final_result
            
        except Exception as e:
            logger.error(f"Screenshot analysis failed: {e}")
            return self._create_result(False, 0, f"Analysis error: {str(e)}")
    
    async def _perform_ocr_analysis(self, image: np.ndarray) -> Dict[str, Any]:
        """OCR analizi gerçekleştir"""
        results = {
            'tesseract_text': '',
            'easyocr_text': '',
            'detected_keywords': [],
            'confidence_scores': [],
            'text_regions': []
        }
        
        try:
            # Tesseract OCR
            tesseract_text = pytesseract.image_to_string(image, config=self.tesseract_config)
            results['tesseract_text'] = tesseract_text.strip()
            
            # EasyOCR
            if self.easyocr_reader:
                easyocr_results = self.easyocr_reader.readtext(image)
                easyocr_text = ' '.join([result[1] for result in easyocr_results])
                results['easyocr_text'] = easyocr_text.strip()
                
                # Text regions
                results['text_regions'] = [
                    {
                        'bbox': result[0],
                        'text': result[1],
                        'confidence': result[2]
                    }
                    for result in easyocr_results
                ]
            
            # Keyword detection
            combined_text = f"{results['tesseract_text']} {results['easyocr_text']}"
            detected_keywords = self._detect_keywords(combined_text)
            results['detected_keywords'] = detected_keywords
            
            # Pattern matching
            pattern_matches = self._match_patterns(combined_text)
            results['pattern_matches'] = pattern_matches
            
            return results
            
        except Exception as e:
            logger.error(f"OCR analysis failed: {e}")
            return results
    
    async def _perform_ai_analysis(self, image: np.ndarray) -> Dict[str, Any]:
        """AI görüntü analizi"""
        results = {
            'menu_detected': False,
            'menu_type': None,
            'confidence': 0.0,
            'ui_elements': [],
            'color_analysis': {},
            'layout_analysis': {}
        }
        
        try:
            # Menü layout tespiti
            layout_result = await self._detect_menu_layout(image)
            results['layout_analysis'] = layout_result
            
            # UI element tespiti
            ui_elements = await self._detect_ui_elements(image)
            results['ui_elements'] = ui_elements
            
            # Renk analizi
            color_analysis = await self._analyze_colors(image)
            results['color_analysis'] = color_analysis
            
            # Menü signature tespiti
            signature_result = await self._detect_menu_signature(image)
            results.update(signature_result)
            
            return results
            
        except Exception as e:
            logger.error(f"AI analysis failed: {e}")
            return results
    
    def _detect_keywords(self, text: str) -> List[Dict[str, Any]]:
        """Cheat menü anahtar kelimelerini tespit et"""
        detected = []
        text_lower = text.lower()
        
        for category, keywords in self.menu_keywords.items():
            for keyword in keywords:
                if keyword.lower() in text_lower:
                    # Context analizi
                    context = self._extract_context(text, keyword)
                    
                    detected.append({
                        'keyword': keyword,
                        'category': category,
                        'context': context,
                        'confidence': self._calculate_keyword_confidence(keyword, context)
                    })
        
        return detected
    
    def _match_patterns(self, text: str) -> List[Dict[str, Any]]:
        """Regex pattern'leri ile eşleştir"""
        matches = []
        
        for pattern_name, pattern_data in self.cheat_patterns.items():
            pattern = pattern_data['pattern']
            severity = pattern_data['severity']
            
            regex_matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in regex_matches:
                matches.append({
                    'pattern_name': pattern_name,
                    'matched_text': match.group(),
                    'severity': severity,
                    'position': match.span()
                })
        
        return matches
    
    async def _detect_menu_layout(self, image: np.ndarray) -> Dict[str, Any]:
        """Menü layout'unu tespit et"""
        try:
            # Kenar tespiti
            edges = cv2.Canny(image, 50, 150)
            
            # Contour tespiti
            contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            # Dikdörtgen alanları tespit et
            rectangles = []
            for contour in contours:
                x, y, w, h = cv2.boundingRect(contour)
                if w > 100 and h > 50:  # Minimum menü boyutu
                    rectangles.append({
                        'x': int(x), 'y': int(y),
                        'width': int(w), 'height': int(h),
                        'area': int(w * h)
                    })
            
            # Menü benzeri yapıları tespit et
            menu_candidates = []
            for rect in rectangles:
                aspect_ratio = rect['width'] / rect['height']
                if 0.5 <= aspect_ratio <= 3.0:  # Menü aspect ratio'su
                    menu_candidates.append(rect)
            
            return {
                'total_rectangles': len(rectangles),
                'menu_candidates': menu_candidates,
                'has_menu_layout': len(menu_candidates) > 0
            }
            
        except Exception as e:
            logger.error(f"Menu layout detection failed: {e}")
            return {'has_menu_layout': False}
    
    async def _detect_ui_elements(self, image: np.ndarray) -> List[Dict[str, Any]]:
        """UI elementlerini tespit et"""
        elements = []
        
        try:
            # Template matching için UI element şablonları
            templates = {
                'checkbox': self._load_template('checkbox'),
                'button': self._load_template('button'),
                'slider': self._load_template('slider'),
                'dropdown': self._load_template('dropdown')
            }
            
            for element_type, template in templates.items():
                if template is not None:
                    matches = cv2.matchTemplate(image, template, cv2.TM_CCOEFF_NORMED)
                    locations = np.where(matches >= 0.7)
                    
                    for pt in zip(*locations[::-1]):
                        elements.append({
                            'type': element_type,
                            'position': {'x': int(pt[0]), 'y': int(pt[1])},
                            'confidence': float(matches[pt[1], pt[0]])
                        })
            
            return elements
            
        except Exception as e:
            logger.error(f"UI element detection failed: {e}")
            return []
    
    async def _analyze_colors(self, image: np.ndarray) -> Dict[str, Any]:
        """Renk analizi yap"""
        try:
            # Dominant renkleri tespit et
            pixels = image.reshape(-1, 3)
            unique_colors, counts = np.unique(pixels, axis=0, return_counts=True)
            
            # En yaygın renkleri al
            top_colors = []
            sorted_indices = np.argsort(counts)[::-1][:10]
            
            for idx in sorted_indices:
                color = unique_colors[idx]
                count = counts[idx]
                percentage = (count / len(pixels)) * 100
                
                top_colors.append({
                    'rgb': color.tolist(),
                    'hex': '#{:02x}{:02x}{:02x}'.format(color[0], color[1], color[2]),
                    'percentage': float(percentage)
                })
            
            # Cheat menü renk kalıplarını kontrol et
            suspicious_colors = self._check_suspicious_colors(top_colors)
            
            return {
                'dominant_colors': top_colors,
                'suspicious_colors': suspicious_colors,
                'color_diversity': len(unique_colors)
            }
            
        except Exception as e:
            logger.error(f"Color analysis failed: {e}")
            return {}
    
    async def _detect_menu_signature(self, image: np.ndarray) -> Dict[str, Any]:
        """Bilinen menü signature'larını tespit et"""
        try:
            # Image hash hesapla
            image_hash = self._calculate_image_hash(image)
            
            # Signature matching
            for menu_name, signature_data in self.menu_signatures.items():
                similarity = self._compare_signatures(image_hash, signature_data['hash'])
                
                if similarity > signature_data['threshold']:
                    return {
                        'menu_detected': True,
                        'menu_type': menu_name,
                        'confidence': similarity,
                        'signature_match': True
                    }
            
            return {
                'menu_detected': False,
                'signature_match': False
            }
            
        except Exception as e:
            logger.error(f"Menu signature detection failed: {e}")
            return {'menu_detected': False}
    
    async def _evaluate_results(self, ocr_results: Dict, ai_results: Dict, metadata: Dict = None) -> Dict[str, Any]:
        """Sonuçları değerlendir ve final kararı ver"""
        
        # Confidence skorları
        ocr_confidence = self._calculate_ocr_confidence(ocr_results)
        ai_confidence = ai_results.get('confidence', 0.0)
        
        # Ağırlıklı skor hesapla
        weights = {
            'ocr': 0.4,
            'ai': 0.3,
            'keywords': 0.2,
            'patterns': 0.1
        }
        
        keyword_score = len(ocr_results.get('detected_keywords', [])) * 0.2
        pattern_score = len(ocr_results.get('pattern_matches', [])) * 0.3
        
        final_confidence = (
            ocr_confidence * weights['ocr'] +
            ai_confidence * weights['ai'] +
            min(keyword_score, 1.0) * weights['keywords'] +
            min(pattern_score, 1.0) * weights['patterns']
        )
        
        # Tespit kararı
        detection_threshold = self.config.get('detection_threshold', 0.7)
        detected = final_confidence >= detection_threshold
        
        # Detaylı sonuç
        result = {
            'detected': detected,
            'confidence': final_confidence,
            'detection_type': 'cheat_menu' if detected else 'clean',
            'ocr_results': ocr_results,
            'ai_results': ai_results,
            'analysis_details': {
                'ocr_confidence': ocr_confidence,
                'ai_confidence': ai_confidence,
                'keyword_score': keyword_score,
                'pattern_score': pattern_score,
                'threshold_used': detection_threshold
            },
            'timestamp': datetime.now().isoformat(),
            'processing_time': 0  # Will be set by caller
        }
        
        return result
    
    def _decode_image(self, image_data: str) -> Optional[np.ndarray]:
        """Base64 görüntüyü decode et"""
        try:
            # Base64 prefix'ini kaldır
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            # Decode et
            image_bytes = base64.b64decode(image_data)
            
            # PIL Image'a çevir
            pil_image = Image.open(io.BytesIO(image_bytes))
            
            # RGB'ye çevir
            if pil_image.mode != 'RGB':
                pil_image = pil_image.convert('RGB')
            
            # NumPy array'e çevir
            image_array = np.array(pil_image)
            
            return image_array
            
        except Exception as e:
            logger.error(f"Image decode failed: {e}")
            return None
    
    async def _preprocess_image(self, image: np.ndarray) -> np.ndarray:
        """Görüntüyü ön işle"""
        try:
            # PIL Image'a çevir
            pil_image = Image.fromarray(image)
            
            # Kontrast artır
            enhancer = ImageEnhance.Contrast(pil_image)
            pil_image = enhancer.enhance(1.5)
            
            # Keskinlik artır
            enhancer = ImageEnhance.Sharpness(pil_image)
            pil_image = enhancer.enhance(1.2)
            
            # Gürültü azalt
            pil_image = pil_image.filter(ImageFilter.MedianFilter(size=3))
            
            # NumPy'ye geri çevir
            processed_image = np.array(pil_image)
            
            return processed_image
            
        except Exception as e:
            logger.error(f"Image preprocessing failed: {e}")
            return image
    
    def _load_menu_keywords(self) -> Dict[str, List[str]]:
        """Menü anahtar kelimelerini yükle"""
        return {
            'aimbot': [
                'aimbot', 'aim bot', 'auto aim', 'aim assist', 'triggerbot',
                'trigger bot', 'silent aim', 'rage bot', 'legit bot'
            ],
            'esp': [
                'esp', 'wallhack', 'wall hack', 'player esp', 'item esp',
                'vehicle esp', 'box esp', 'name esp', 'health esp'
            ],
            'movement': [
                'speed hack', 'fly hack', 'noclip', 'no clip', 'teleport',
                'super jump', 'infinite stamina', 'god mode', 'godmode'
            ],
            'weapon': [
                'infinite ammo', 'no recoil', 'rapid fire', 'one shot',
                'damage multiplier', 'weapon spawn', 'give weapon'
            ],
            'vehicle': [
                'vehicle spawn', 'car fly', 'vehicle god', 'speed boost',
                'vehicle teleport', 'repair vehicle', 'flip vehicle'
            ],
            'menu_names': [
                'lynx', 'dopamine', 'maestro', 'redengine', 'hammafia',
                'desudo', 'tapatio', 'malossi', 'redstonia', 'chocohax',
                'fivesense', 'gamesense', 'absolute', 'hoax', 'fendin'
            ],
            'menu_ui': [
                'menu', 'cheat', 'hack', 'mod menu', 'trainer', 'injector',
                'executor', 'options', 'settings', 'keybind', 'hotkey'
            ]
        }
    
    def _load_cheat_patterns(self) -> Dict[str, Dict[str, Any]]:
        """Cheat pattern'lerini yükle"""
        return {
            'coordinates': {
                'pattern': r'X:\s*-?\d+\.?\d*\s*Y:\s*-?\d+\.?\d*\s*Z:\s*-?\d+\.?\d*',
                'severity': 'medium'
            },
            'health_armor': {
                'pattern': r'Health:\s*\d+\s*Armor:\s*\d+',
                'severity': 'high'
            },
            'weapon_info': {
                'pattern': r'Weapon:\s*\w+\s*Ammo:\s*\d+',
                'severity': 'high'
            },
            'player_count': {
                'pattern': r'Players:\s*\d+/\d+',
                'severity': 'low'
            },
            'menu_version': {
                'pattern': r'v\d+\.\d+\.\d+|version\s*\d+\.\d+',
                'severity': 'high'
            }
        }
    
    def _load_menu_signatures(self) -> Dict[str, Dict[str, Any]]:
        """Menü signature'larını yükle"""
        # Bu gerçek uygulamada veritabanından yüklenecek
        return {
            'lynx_menu': {
                'hash': 'abc123def456',
                'threshold': 0.8
            },
            'dopamine_menu': {
                'hash': 'def456ghi789',
                'threshold': 0.8
            }
        }
    
    def _load_template(self, template_name: str) -> Optional[np.ndarray]:
        """UI element şablonunu yükle"""
        # Bu gerçek uygulamada dosyadan yüklenecek
        return None
    
    def _extract_context(self, text: str, keyword: str) -> str:
        """Anahtar kelimenin context'ini çıkar"""
        keyword_pos = text.lower().find(keyword.lower())
        if keyword_pos == -1:
            return ""
        
        start = max(0, keyword_pos - 50)
        end = min(len(text), keyword_pos + len(keyword) + 50)
        
        return text[start:end].strip()
    
    def _calculate_keyword_confidence(self, keyword: str, context: str) -> float:
        """Anahtar kelime confidence'ını hesapla"""
        base_confidence = 0.5
        
        # Context analizi
        if any(word in context.lower() for word in ['menu', 'cheat', 'hack']):
            base_confidence += 0.3
        
        if any(word in context.lower() for word in ['enable', 'disable', 'toggle']):
            base_confidence += 0.2
        
        return min(base_confidence, 1.0)
    
    def _calculate_ocr_confidence(self, ocr_results: Dict) -> float:
        """OCR confidence'ını hesapla"""
        keyword_count = len(ocr_results.get('detected_keywords', []))
        pattern_count = len(ocr_results.get('pattern_matches', []))
        
        # Basit confidence hesaplama
        confidence = min((keyword_count * 0.2) + (pattern_count * 0.3), 1.0)
        
        return confidence
    
    def _check_suspicious_colors(self, colors: List[Dict]) -> List[Dict]:
        """Şüpheli renkleri kontrol et"""
        suspicious = []
        
        # Bilinen cheat menü renkleri
        cheat_colors = [
            {'rgb': [255, 0, 0], 'name': 'red_menu'},      # Kırmızı menüler
            {'rgb': [0, 255, 0], 'name': 'green_menu'},    # Yeşil menüler
            {'rgb': [0, 0, 255], 'name': 'blue_menu'},     # Mavi menüler
            {'rgb': [255, 255, 0], 'name': 'yellow_menu'}  # Sarı menüler
        ]
        
        for color in colors:
            for cheat_color in cheat_colors:
                similarity = self._color_similarity(color['rgb'], cheat_color['rgb'])
                if similarity > 0.8:
                    suspicious.append({
                        'color': color,
                        'matched_pattern': cheat_color['name'],
                        'similarity': similarity
                    })
        
        return suspicious
    
    def _color_similarity(self, color1: List[int], color2: List[int]) -> float:
        """İki renk arasındaki benzerliği hesapla"""
        diff = sum(abs(c1 - c2) for c1, c2 in zip(color1, color2))
        max_diff = 255 * 3
        similarity = 1.0 - (diff / max_diff)
        return similarity
    
    def _calculate_image_hash(self, image: np.ndarray) -> str:
        """Görüntü hash'i hesapla"""
        # Basit perceptual hash
        resized = cv2.resize(image, (8, 8))
        gray = cv2.cvtColor(resized, cv2.COLOR_RGB2GRAY)
        
        # DCT
        dct = cv2.dct(np.float32(gray))
        dct_low = dct[:8, :8]
        
        # Hash oluştur
        median = np.median(dct_low)
        hash_bits = dct_low > median
        
        # Binary string'e çevir
        hash_str = ''.join(['1' if bit else '0' for bit in hash_bits.flatten()])
        
        return hash_str
    
    def _compare_signatures(self, hash1: str, hash2: str) -> float:
        """İki signature'ı karşılaştır"""
        if len(hash1) != len(hash2):
            return 0.0
        
        matches = sum(c1 == c2 for c1, c2 in zip(hash1, hash2))
        similarity = matches / len(hash1)
        
        return similarity
    
    def _create_result(self, detected: bool, confidence: float, message: str = "") -> Dict[str, Any]:
        """Standart sonuç objesi oluştur"""
        return {
            'detected': detected,
            'confidence': confidence,
            'message': message,
            'timestamp': datetime.now().isoformat()
        }
    
    def _update_stats(self, detected: bool, processing_time: float):
        """İstatistikleri güncelle"""
        self.stats['total_processed'] += 1
        if detected:
            self.stats['detections'] += 1
        self.stats['processing_time'].append(processing_time)
        
        # Son 1000 işlemi tut
        if len(self.stats['processing_time']) > 1000:
            self.stats['processing_time'] = self.stats['processing_time'][-1000:]
    
    async def _save_analysis_result(self, player_id: str, result: Dict, image_data: str):
        """Analiz sonucunu kaydet"""
        try:
            # Sadece tespit edilen durumları kaydet
            if result['detected']:
                # Burada veritabanına veya dosyaya kaydetme işlemi yapılacak
                logger.info(f"Detection saved for player {player_id}: {result['detection_type']}")
        except Exception as e:
            logger.error(f"Failed to save analysis result: {e}")
    
    async def _load_ai_models(self):
        """AI modellerini yükle"""
        try:
            # Text classification model
            self.text_classifier = pipeline(
                "text-classification",
                model="distilbert-base-uncased",
                device=0 if torch.cuda.is_available() else -1
            )
            
            logger.info("AI models loaded successfully")
            
        except Exception as e:
            logger.warning(f"AI models could not be loaded: {e}")
    
    def get_stats(self) -> Dict[str, Any]:
        """İstatistikleri getir"""
        avg_processing_time = 0
        if self.stats['processing_time']:
            avg_processing_time = sum(self.stats['processing_time']) / len(self.stats['processing_time'])
        
        return {
            'total_processed': self.stats['total_processed'],
            'detections': self.stats['detections'],
            'detection_rate': self.stats['detections'] / max(self.stats['total_processed'], 1),
            'avg_processing_time': avg_processing_time,
            'false_positives': self.stats['false_positives']
        }
    
    async def health_check(self) -> bool:
        """Sağlık kontrolü"""
        try:
            # Test image ile kontrol
            test_image = np.zeros((100, 100, 3), dtype=np.uint8)
            result = await self._perform_ocr_analysis(test_image)
            return True
        except:
            return False
