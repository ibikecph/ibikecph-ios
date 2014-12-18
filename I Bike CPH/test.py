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
 
time.sleep(3)
 
skip_button = driver.find_element_by_accessibility_id('SKIP')
self.assertIsNotNone(skip_button)
skip_button.click()
#
# # we may get to another page of skipping
# skip_button = driver.find_element_by_android_uiautomator('new UiSelector().text("SKIP")')
# if skip_button is not None:
#     skip_button.click()
#     skip_button.click()
#
# # Find the search button
# search_button = driver.find_element_by_class_name("android.widget.ImageButton")
# search_button.click()
#
# # Find the destination field
# dst_field = driver.find_elements_by_class_name("android.widget.TextView")[1]
# dst_field.click()
#
# # New activity, new destination field
# dst_field2 = driver.find_element_by_class_name("android.widget.EditText")
# dst_field2.click()
# driver.sendKeys("Rovsingsgade 47, 2200 Kobenhavn N")