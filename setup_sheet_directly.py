#!/usr/bin/env python3
"""
Direct Google Sheets Setup Script for PTracker
This script will set up your Google Sheet with the proper headers and data
"""

import os
import json
from datetime import datetime, timedelta
import uuid

# Install required packages if needed
try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    print("Installing required packages...")
    os.system("pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib")
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError

# If modifying these scopes, delete the file token.json.
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']

# Your spreadsheet ID
SPREADSHEET_ID = '1H3EOvKRu4YUl2BldU6dNR0YdaDUIMC0Oa4xkuqInET0'

def authenticate_google_sheets():
    """Authenticate and return Google Sheets service object"""
    creds = None
    
    # The file token.json stores the user's access and refresh tokens
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    
    # If there are no (valid) credentials available, let the user log in
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            # First, we need credentials.json from Google Cloud Console
            if not os.path.exists('credentials.json'):
                print("\n⚠️  credentials.json not found!")
                print("\nTo set up authentication:")
                print("1. Go to https://console.cloud.google.com/")
                print("2. Create a new project or select existing")
                print("3. Enable Google Sheets API")
                print("4. Create credentials (OAuth 2.0 Client ID)")
                print("5. Download as credentials.json to this directory")
                return None
            
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save the credentials for the next run
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
    
    return build('sheets', 'v4', credentials=creds)

def setup_headers(service):
    """Set up the header row in the spreadsheet"""
    headers = [['ID', 'StartDate', 'EndDate', 'Duration', 'Notes']]
    
    body = {
        'values': headers
    }
    
    try:
        result = service.spreadsheets().values().update(
            spreadsheetId=SPREADSHEET_ID,
            range='A1:E1',
            valueInputOption='RAW',
            body=body
        ).execute()
        
        print(f"✅ Headers added: {result.get('updatedCells')} cells updated")
        return True
    except HttpError as error:
        print(f"❌ An error occurred: {error}")
        return False

def add_period_data(service):
    """Add your period history to the spreadsheet"""
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
    
    values = []
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
        
        values.append([period_id, start_iso, end_iso, str(duration), ''])
    
    body = {
        'values': values
    }
    
    try:
        result = service.spreadsheets().values().update(
            spreadsheetId=SPREADSHEET_ID,
            range='A2:E8',
            valueInputOption='RAW',
            body=body
        ).execute()
        
        print(f"✅ Period data added: {result.get('updatedCells')} cells updated")
        return True
    except HttpError as error:
        print(f"❌ An error occurred: {error}")
        return False

def format_sheet(service):
    """Apply formatting to make the sheet look nice"""
    requests = [
        # Bold the header row
        {
            "repeatCell": {
                "range": {
                    "sheetId": 0,
                    "startRowIndex": 0,
                    "endRowIndex": 1
                },
                "cell": {
                    "userEnteredFormat": {
                        "textFormat": {
                            "bold": True
                        },
                        "backgroundColor": {
                            "red": 0.9,
                            "green": 0.9,
                            "blue": 0.9
                        }
                    }
                },
                "fields": "userEnteredFormat(textFormat,backgroundColor)"
            }
        },
        # Auto-resize columns
        {
            "autoResizeDimensions": {
                "dimensions": {
                    "sheetId": 0,
                    "dimension": "COLUMNS",
                    "startIndex": 0,
                    "endIndex": 5
                }
            }
        }
    ]
    
    body = {
        'requests': requests
    }
    
    try:
        service.spreadsheets().batchUpdate(
            spreadsheetId=SPREADSHEET_ID,
            body=body
        ).execute()
        
        print("✅ Formatting applied")
        return True
    except HttpError as error:
        print(f"❌ Formatting error: {error}")
        return False

def main():
    """Main function to set up the Google Sheet"""
    print("🚀 PTracker Google Sheets Setup")
    print(f"📊 Sheet ID: {SPREADSHEET_ID}")
    print("-" * 50)
    
    # Authenticate
    service = authenticate_google_sheets()
    if not service:
        return
    
    print("\n📝 Setting up your Google Sheet...")
    
    # Set up headers
    if setup_headers(service):
        print("✓ Headers configured")
    
    # Add period data
    if add_period_data(service):
        print("✓ Period history added")
    
    # Format the sheet
    if format_sheet(service):
        print("✓ Formatting applied")
    
    print("\n✅ Setup complete!")
    print(f"\n🔗 View your sheet: https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit")
    
    # Make sheet publicly readable
    print("\n📢 Remember to make your sheet publicly readable:")
    print("1. Open the sheet")
    print("2. Click Share → Change to 'Anyone with the link can view'")
    print("3. Click Done")

if __name__ == '__main__':
    main()