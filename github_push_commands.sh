#!/bin/bash

# Commands to push PTracker to GitHub

# First, authenticate with GitHub CLI (if not already done):
# gh auth login

# Create a new private repository on GitHub:
gh repo create PTracker --private --source=. --description="Personal iOS period tracking app"

# If the above doesn't work, use these commands after creating the repo on GitHub:
# git remote add origin https://github.com/YOUR_USERNAME/PTracker.git
# git branch -M main
# git push -u origin main

echo "Repository created and code pushed to GitHub!"