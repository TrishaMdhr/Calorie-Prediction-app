from selenium import webdriver

chrome_options = webdriver.chromeoptions()
chrome_options.add.experimental.option("detach", True)

driver = webdriver.chrome(options = chrome_options)

driver.get('https://iimscollege.edu.np')
actionButton = driver.find.element(webdriver.By.CSS_SELECTOR,'btn.btn.outline primary')
actionButton.click()