#!/usr/bin/env python3
"""
Quick Google Sheets Setup using API Key (Public Sheet)
This creates the structure and sample data for manual copy-paste
"""

import requests
import json
from datetime import datetime, timedelta
import uuid

SPREADSHEET_ID = '1H3EOvKRu4YUl2BldU6dNR0YdaDUIMC0Oa4xkuqInET0'

def generate_csv_data():
    """Generate CSV data for the sheet"""
    # Your period data
    periods = [
        ("2025-01-14", 7),
        ("2025-02-15", 7),
        ("2025-03-16", 7),
        ("2025-04-15", 7),
        ("2025-05-10", 7),
        ("2025-06-09", 7),
        ("2025-07-09", 7),
    ]
    
    # Headers
    csv_lines = ["ID,StartDate,EndDate,Duration,Notes"]
    
    for start_date_str, duration in periods:
        # Generate UUID
        period_id = str(uuid.uuid4())
        
        # Parse start date
        start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
        
        # Calculate end date
        end_date = start_date + timedelta(days=duration - 1)
        
        # Format dates in ISO8601
        start_iso = start_date.strftime("%Y-%m-%dT%H:%M:%SZ")
        end_iso = end_date.strftime("%Y-%m-%dT%H:%M:%SZ")
        
        csv_lines.append(f"{period_id},{start_iso},{end_iso},{duration},")
    
    return "\n".join(csv_lines)

def main():
    print("🚀 PTracker Google Sheets Quick Setup")
    print(f"📊 Sheet URL: https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit")
    print("=" * 60)
    
    # Generate CSV data
    csv_data = generate_csv_data()
    
    # Save to file
    with open('ptracker_data.csv', 'w') as f:
        f.write(csv_data)
    
    print("\n✅ Generated ptracker_data.csv")
    print("\n📋 Instructions:")
    print("1. Open your Google Sheet")
    print("2. Click File → Import")
    print("3. Upload 'ptracker_data.csv'")
    print("4. Choose 'Replace current sheet'")
    print("5. Click 'Import data'")
    print("\n🔒 Then make it readable:")
    print("1. Click Share button")
    print("2. Change to 'Anyone with the link can view'")
    print("3. Click Done")
    
    print("\n📄 CSV Preview:")
    print("-" * 60)
    print(csv_data)
    print("-" * 60)
    
    print("\n✅ Your app is already configured with this Sheet ID!")
    print("Once you import the data and share the sheet, sync will work.")

if __name__ == '__main__':
    main()