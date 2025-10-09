#!/usr/bin/env python3
"""
QR Code Generator Script for PrimeWinTools
This script generates QR codes and can be called from Flutter/Dart
"""

import sys
import os
import json
import argparse
from pathlib import Path

try:
    import qrcode
    from qrcode.image.styledpil import StyledPilImage
    from qrcode.image.styles.moduledrawers import RoundedModuleDrawer, SquareModuleDrawer, CircleModuleDrawer
    from PIL import Image, ImageDraw
    QR_AVAILABLE = True
except ImportError:
    QR_AVAILABLE = False

def install_requirements():
    """Install required packages if they're not available"""
    import subprocess
    packages = ['qrcode[pil]', 'Pillow']
    
    for package in packages:
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
            print(f"Successfully installed {package}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to install {package}: {e}")
            return False
    return True

def generate_qr_code(data, output_path=None, size=512, border=4, 
                    error_correction='M', fg_color='black', bg_color='white',
                    style='square', format='PNG'):
    """
    Generate a QR code with the given parameters
    
    Args:
        data (str): The data to encode in the QR code
        output_path (str): Path to save the QR code image
        size (int): Size of the QR code in pixels
        border (int): Border size in modules
        error_correction (str): Error correction level (L, M, Q, H)
        fg_color (str): Foreground color
        bg_color (str): Background color
        style (str): Module style (square, rounded, circle)
        format (str): Image format (PNG, JPEG, etc.)
    
    Returns:
        dict: Result with success status and message
    """
    
    if not QR_AVAILABLE:
        return {
            'success': False,
            'error': 'QR code libraries not installed. Run with --install to install them.',
            'output_path': None
        }
    
    try:
        # Map error correction levels
        error_levels = {
            'L': qrcode.constants.ERROR_CORRECT_L,
            'M': qrcode.constants.ERROR_CORRECT_M,
            'Q': qrcode.constants.ERROR_CORRECT_Q,
            'H': qrcode.constants.ERROR_CORRECT_H
        }
        
        # Create QR code instance
        qr = qrcode.QRCode(
            version=1,  # Let it auto-determine the version
            error_correction=error_levels.get(error_correction, qrcode.constants.ERROR_CORRECT_M),
            box_size=max(1, size // 25),  # Calculate box size based on desired final size
            border=border,
        )
        
        # Add data
        qr.add_data(data)
        qr.make(fit=True)
        
        # Choose module drawer based on style
        module_drawer = None
        if style == 'rounded':
            module_drawer = RoundedModuleDrawer()
        elif style == 'circle':
            module_drawer = CircleModuleDrawer()
        else:  # square or default
            module_drawer = SquareModuleDrawer()
        
        # Create image
        if style != 'square':
            img = qr.make_image(
                image_factory=StyledPilImage,
                module_drawer=module_drawer,
                fill_color=fg_color,
                back_color=bg_color
            )
        else:
            img = qr.make_image(fill_color=fg_color, back_color=bg_color)
        
        # Resize to exact size if needed
        if img.size[0] != size:
            img = img.resize((size, size), Image.Resampling.NEAREST)
        
        # Save or return
        if output_path:
            # Ensure directory exists
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)
            img.save(output_path, format=format)
            
            return {
                'success': True,
                'message': f'QR code generated successfully',
                'output_path': str(Path(output_path).absolute()),
                'size': f"{img.size[0]}x{img.size[1]}",
                'format': format
            }
        else:
            # Return base64 encoded image
            import io
            import base64
            
            buffer = io.BytesIO()
            img.save(buffer, format=format)
            img_str = base64.b64encode(buffer.getvalue()).decode()
            
            return {
                'success': True,
                'message': 'QR code generated successfully',
                'base64': img_str,
                'size': f"{img.size[0]}x{img.size[1]}",
                'format': format
            }
            
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'output_path': output_path
        }

def create_wifi_qr(ssid, password, security='WPA', hidden=False):
    """Create WiFi QR code data string"""
    hidden_str = 'true' if hidden else 'false'
    return f"WIFI:T:{security};S:{ssid};P:{password};H:{hidden_str};;"

def create_vcard_qr(name, phone='', email='', organization='', url=''):
    """Create vCard QR code data string"""
    vcard = f"""BEGIN:VCARD
VERSION:3.0
FN:{name}"""
    
    if phone:
        vcard += f"\nTEL:{phone}"
    if email:
        vcard += f"\nEMAIL:{email}"
    if organization:
        vcard += f"\nORG:{organization}"
    if url:
        vcard += f"\nURL:{url}"
    
    vcard += "\nEND:VCARD"
    return vcard

def main():
    parser = argparse.ArgumentParser(description='Generate QR codes')
    parser.add_argument('--install', action='store_true', help='Install required packages')
    parser.add_argument('--data', '-d', type=str, help='Data to encode')
    parser.add_argument('--output', '-o', type=str, help='Output file path')
    parser.add_argument('--size', '-s', type=int, default=512, help='QR code size in pixels')
    parser.add_argument('--border', '-b', type=int, default=4, help='Border size in modules')
    parser.add_argument('--error-correction', '-e', choices=['L', 'M', 'Q', 'H'], default='M', help='Error correction level')
    parser.add_argument('--fg-color', default='black', help='Foreground color')
    parser.add_argument('--bg-color', default='white', help='Background color')
    parser.add_argument('--style', choices=['square', 'rounded', 'circle'], default='square', help='Module style')
    parser.add_argument('--format', choices=['PNG', 'JPEG', 'BMP'], default='PNG', help='Output format')
    parser.add_argument('--json', action='store_true', help='Output result as JSON')
    
    # Special QR types
    parser.add_argument('--wifi', action='store_true', help='Generate WiFi QR code')
    parser.add_argument('--ssid', type=str, help='WiFi SSID')
    parser.add_argument('--password', type=str, help='WiFi password')
    parser.add_argument('--security', choices=['WPA', 'WEP', 'nopass'], default='WPA', help='WiFi security')
    
    parser.add_argument('--vcard', action='store_true', help='Generate vCard QR code')
    parser.add_argument('--name', type=str, help='Contact name')
    parser.add_argument('--phone', type=str, help='Contact phone')
    parser.add_argument('--email', type=str, help='Contact email')
    parser.add_argument('--organization', type=str, help='Contact organization')
    parser.add_argument('--url', type=str, help='Contact URL')
    
    args = parser.parse_args()
    
    # Install packages if requested
    if args.install:
        if install_requirements():
            print("Successfully installed all required packages!")
            return 0
        else:
            print("Failed to install some packages.")
            return 1
    
    # Determine data to encode
    data = None
    if args.wifi:
        if not args.ssid:
            print("Error: --ssid is required for WiFi QR codes")
            return 1
        data = create_wifi_qr(args.ssid, args.password or '', args.security)
    elif args.vcard:
        if not args.name:
            print("Error: --name is required for vCard QR codes")
            return 1
        data = create_vcard_qr(args.name, args.phone or '', args.email or '', 
                              args.organization or '', args.url or '')
    elif args.data:
        data = args.data
    else:
        print("Error: No data specified. Use --data, --wifi, or --vcard")
        return 1
    
    # Generate QR code
    result = generate_qr_code(
        data=data,
        output_path=args.output,
        size=args.size,
        border=args.border,
        error_correction=args.error_correction,
        fg_color=args.fg_color,
        bg_color=args.bg_color,
        style=args.style,
        format=args.format
    )
    
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if result['success']:
            print(f"Success: {result['message']}")
            if 'output_path' in result:
                print(f"Saved to: {result['output_path']}")
            if 'size' in result:
                print(f"Size: {result['size']}")
        else:
            print(f"Error: {result['error']}")
            return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main())