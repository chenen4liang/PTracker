# Google Sheets API Setup for PTracker

## Step 1: Enable Google Sheets API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Click on "APIs & Services" → "Enable APIs and Services"
4. Search for "Google Sheets API"
5. Click on it and press "Enable"

## Step 2: Create Service Account Credentials

1. In Google Cloud Console, go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "Service Account"
3. Fill in:
   - Service account name: `ptracker-service`
   - Service account ID: (auto-generated)
   - Description: "Service account for PTracker app"
4. Click "Create and Continue"
5. Skip the optional permissions (click "Continue")
6. Click "Done"

## Step 3: Create and Download Key

1. Click on the service account you just created
2. Go to "Keys" tab
3. Click "Add Key" → "Create new key"
4. Choose "JSON" format
5. Click "Create" - this will download a JSON file
6. **Save this file securely** - you'll need it for the app

## Step 4: Create Google Sheet

1. Go to [Google Sheets](https://sheets.google.com)
2. Create a new spreadsheet
3. Name it "PTracker Data"
4. Set up the following columns in Sheet1:
   - A1: `ID`
   - B1: `StartDate`
   - C1: `EndDate`
   - D1: `Duration`
   - E1: `CycleLength`
   - F1: `LastUpdated`

## Step 5: Share Sheet with Service Account

1. In your Google Sheet, click "Share" button
2. Copy the service account email from your JSON file (looks like: `ptracker-service@your-project.iam.gserviceaccount.com`)
3. Paste it in the share dialog
4. Give it "Editor" permission
5. Click "Send"

## Step 6: Get Sheet ID

1. Look at your Google Sheet URL
2. Copy the ID between `/d/` and `/edit`
   - Example: `https://docs.google.com/spreadsheets/d/SHEET_ID_HERE/edit`
3. Save this ID - you'll need it in the app

## Next Steps

Once you've completed these steps, we'll:
1. Add Google Sheets API to your iOS project
2. Implement the sync functionality
3. Test reading and writing data