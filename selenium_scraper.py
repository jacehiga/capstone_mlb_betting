from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import json
import time
from datetime import datetime

# Set up headless browser
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--disable-gpu")
options.add_argument("--disable-notifications")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(
    service=Service(ChromeDriverManager().install()),
    options=options
)
wait = WebDriverWait(driver, 10)

# Go to MLB scores page
url = "https://www.mlb.com/scores/2025-06-10"
driver.get(url)

# Wait for page to load
wait.until(EC.presence_of_all_elements_located((By.XPATH, "//button[span[normalize-space()='Box']]")))

# Dismiss overlay if it exists
try:
    overlay = driver.find_element(By.CLASS_NAME, "onetrust-close-btn-container")
    overlay.click()
    time.sleep(1)
except:
    pass  # No overlay

# Find all "Box" buttons
box_buttons = driver.find_elements(By.XPATH, "//button[span[normalize-space()='Box']]")
print(f"Found {len(box_buttons)} 'Box' buttons.")


page_date = datetime.today().strftime('%Y-%m-%d')
results = []

for i in range(len(box_buttons)):
    try:
        # Refetch buttons on each loop since DOM may reload
        box_buttons = driver.find_elements(By.XPATH, "//button[span[normalize-space()='Box']]")
        button = box_buttons[i]

        # Click via JavaScript to avoid intercept issues
        driver.execute_script("arguments[0].click();", button)
        print(f"Clicked Box button {i + 1}")

        # Wait for boxscore content to load
        wait.until(lambda d: len(d.find_element(By.XPATH, "//*[@id='gameday-index-component__root']").text.strip()) > 100)

        # Extract data from the specified XPath
        content = driver.find_element(By.XPATH, "//*[@id='gameday-index-component__root']").text
        results.append({"game_index": i + 1, "game_date": page_date, "box_score": content})

        # Go back to main scores page
        driver.back()
        wait.until(EC.presence_of_all_elements_located((By.XPATH, "//button[span[normalize-space()='Box']]")))

    except Exception as e:
        print(f" Error on game {i + 1}: {e}")
        continue

# Save to JSONL
with open("mlb_box_scores.jsonl", "w") as f:
    for row in results:
        json.dump(row, f)
        f.write("\n")


print(f"\n Saved {len(results)} box scores to mlb_box_scores.jsonl")

driver.quit()
