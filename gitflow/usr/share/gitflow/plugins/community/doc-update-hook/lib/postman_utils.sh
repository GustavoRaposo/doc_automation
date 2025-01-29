#!/usr/bin/env python3

import json
import os
import re
from datetime import datetime
from typing import Dict, List, Any

def normalize_url(url: str) -> str:
    """Normalize URL by removing host, api version prefix and query parameters."""
    url = url.split('?')[0]
    
    if 'https://' in url:
        parts = url.split('/', 3)
        url = parts[-1] if len(parts) > 3 else url
    
    for prefix in ['/api/v1/', '/api/', 'api/v1/', 'api/']:
        if url.startswith(prefix):
            url = url[len(prefix):]
            break
    
    return f"/{url.lstrip('/')}"

def sanitize_filename(name: str) -> str:
    """Create a safe filename from a string."""
    name = re.sub(r'[<>:"/\\|?*]', '_', name)
    return name.replace(' ', '_').lower()

def process_collection_items(new_items: List[Dict], 
                           existing_items: Dict,
                           collections_dir: str,
                           items_dir: str) -> Dict:
    """Process and update collection items."""
    final_items = existing_items.copy()
    updated_endpoints = {}
    
    for item in new_items:
        method = item.get('request', {}).get('method', '')
        original_url = item.get('request', {}).get('url', '')
        normalized_url = normalize_url(original_url)
        key = f"{method}:{normalized_url}"
        
        # Save individual item
        timestamp = int(datetime.now().timestamp())
        safe_name = sanitize_filename(item['name'])
        filename = f"item_{timestamp}_{safe_name}.json"
        item_path = os.path.join(items_dir, filename)
        
        with open(item_path, 'w') as f:
            json.dump(item, f, indent=2)
        
        final_items[key] = item
        updated_endpoints[key] = {
            'method': method,
            'url': normalized_url,
            'name': item['name'],
            'lastUpdated': datetime.now().isoformat()
        }
    
    return final_items, updated_endpoints