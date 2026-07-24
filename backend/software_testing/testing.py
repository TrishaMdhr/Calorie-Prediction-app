from selenium import webdriver
from selenium.webdriver.common.by import By

chrome_options = webdriver.ChromeOptions()
chrome_options.add_experimental_option("detach", True)

driver = webdriver.Chrome(options=chrome_options)

driver.get('https://iimscollege.edu.np')
actionButton = driver.find_element(By.CSS_SELECTOR, '.btn.btn-outline-primary')
actionButton.click()
