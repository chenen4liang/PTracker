# Setup Instructions for Your Google Sheet

## Your Sheet URL:
https://docs.google.com/spreadsheets/d/1H3EOvKRu4YUl2BldU6dNR0YdaDUIMC0Oa4xkuqInET0/edit

## Step 1: Add Headers
In your Google Sheet, add these headers in the first row:
- **A1**: ID
- **B1**: StartDate  
- **C1**: EndDate
- **D1**: Duration
- **E1**: Notes

## Step 2: Make Sheet Accessible
1. Click the **Share** button (top right)
2. Click **Change to anyone with the link**
3. Set permission to **Viewer** (for read-only sync)
4. Click **Done**

## Step 3: Add Sample Data (Optional)
If you want to test with sample data, add this in row 2:
- **A2**: `550e8400-e29b-41d4-a716-446655440001`
- **B2**: `2025-01-14T00:00:00Z`
- **C2**: `2025-01-20T00:00:00Z`
- **D2**: `7`
- **E2**: `Sample period`

## Your Current Period Data
Based on your app data, here's your period history in the correct format:

| ID | StartDate | EndDate | Duration | Notes |
|----|-----------|---------|----------|-------|
| (generate UUID) | 2025-01-14T00:00:00Z | 2025-01-20T00:00:00Z | 7 | |
| (generate UUID) | 2025-02-15T00:00:00Z | 2025-02-21T00:00:00Z | 7 | |
| (generate UUID) | 2025-03-16T00:00:00Z | 2025-03-22T00:00:00Z | 7 | |
| (generate UUID) | 2025-04-15T00:00:00Z | 2025-04-21T00:00:00Z | 7 | |
| (generate UUID) | 2025-05-10T00:00:00Z | 2025-05-16T00:00:00Z | 7 | |
| (generate UUID) | 2025-06-09T00:00:00Z | 2025-06-15T00:00:00Z | 7 | |
| (generate UUID) | 2025-07-09T00:00:00Z | 2025-07-15T00:00:00Z | 7 | |

## Notes:
- The app is already configured with your Sheet ID
- Once you set up the headers and sharing, the sync feature will work
- The app currently supports read-only sync
- For write access, we'd need to implement OAuth2 authentication