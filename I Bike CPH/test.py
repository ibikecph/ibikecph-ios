#!/usr/bin/python3
import unittest, time
import selenium
from appium import webdriver
 
# This test installs the app on the device and skips to the map.
desired_caps = {}
desired_caps['platformName'] = 'iOS'
desired_caps['platformVersion'] = '8.1'
desired_caps['deviceName'] = 'iPhone 6'
desired_caps['app'] = '../../../../../../users/duemunk/Gits/ibikecph-ios/I Bike CPH/build/Release-iphonesimulator/CykelPlanen.app'
 
driver = webdriver.Remote('http://localhost:4723/wd/hub', desired_caps)
 
# time.sleep(3)
 
def skip_login():
    skip_button = driver.find_element_by_accessibility_id('SKIP')
    skip_button.click()

def accept_location():
    # Location requires user consent
    driver.find_element_by_name("Allow").click()

def enter_route():
    # Find the search button
    search_button = driver.find_element_by_accessibility_id("SEARCH")
    search_button.click()

def open_destination():
    # Find the destination field
    dst_field = driver.find_element_by_accessibility_id("TO")
    dst_field.click()

def edit_destination():
    # New activity, new destination field
    dst_field2 = driver.find_element_by_accessibility_id("TEXTFIELD")
    dst_field2.click()
    dst_field2.sendKeys("Rovsingsgade 47, 2200 Kobenhavn N")
    
    
if __name__ == "__main__":
    try:
        skip_login()
        accept_location()
        enter_route()
        open_destination()
        edit_destination()

    finally:
        driver.quit()

        # We're done, let's drop a shell
        # ipshell()
    