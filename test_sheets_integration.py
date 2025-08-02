#!/usr/bin/env python3
"""
Test Google Sheets integration with service account
"""

import json
import requests
from google.oauth2 import service_account
from googleapiclient.discovery import build
import uuid
from datetime import datetime, timedelta

# Your spreadsheet ID
SPREADSHEET_ID = '1H3EOvKRu4YUl2BldU6dNR0YdaDUIMC0Oa4xkuqInET0'

# Service account file
SERVICE_ACCOUNT_FILE = '/Users/chenen.liang/Desktop/code/PTracker/PTracker/GoogleServiceAccount.json'

# Scopes
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']

def main():
    print("🚀 Testing Google Sheets Integration")
    
    try:
        # Authenticate using service account
        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE, scopes=SCOPES)
        
        service = build('sheets', 'v4', credentials=credentials)
        sheet = service.spreadsheets()
        
        print("✅ Authentication successful!")
        
        # 1. Set up headers
        headers = [['ID', 'StartDate', 'EndDate', 'Duration', 'Notes']]
        
        result = sheet.values().update(
            spreadsheetId=SPREADSHEET_ID,
            range='A1:E1',
            valueInputOption='RAW',
            body={'values': headers}
        ).execute()
        
        print(f"✅ Headers added: {result.get('updatedCells')} cells updated")
        
        # 2. Add your period data
        periods = [
            ("2025-01-14", 7),
            ("2025-02-15", 7),
            ("2025-03-16", 7),
            ("2025-04-15", 7),
            ("2025-05-10", 7),
            ("2025-06-09", 7),
            ("2025-07-09", 7),
        ]
        
        values = []
        for start_date_str, duration in periods:
            period_id = str(uuid.uuid4())
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
            end_date = start_date + timedelta(days=duration - 1)
            
            start_iso = start_date.strftime("%Y-%m-%dT%H:%M:%SZ")
            end_iso = end_date.strftime("%Y-%m-%dT%H:%M:%SZ")
            
            values.append([period_id, start_iso, end_iso, str(duration), ''])
        
        result = sheet.values().update(
            spreadsheetId=SPREADSHEET_ID,
            range='A2:E8',
            valueInputOption='RAW',
            body={'values': values}
        ).execute()
        
        print(f"✅ Period data added: {result.get('updatedCells')} cells updated")
        
        # 3. Read back the data to verify
        result = sheet.values().get(
            spreadsheetId=SPREADSHEET_ID,
            range='A1:E8'
        ).execute()
        
        values = result.get('values', [])
        print(f"\n📊 Sheet now contains {len(values)} rows:")
        for i, row in enumerate(values[:3]):  # Show first 3 rows
            print(f"   Row {i+1}: {row[:3]}...")  # Show first 3 columns
        
        print("\n✅ Google Sheets integration is working perfectly!")
        print(f"🔗 View your sheet: https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\nTroubleshooting:")
        print("1. Make sure you've shared the sheet with: serviceaccount@stockscan-465621.iam.gserviceaccount.com")
        print("2. Check that the service account has 'Editor' permissions")

if __name__ == '__main__':
    main()