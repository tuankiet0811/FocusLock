@echo off
echo Creating keystore for FocusLock...
"C:\Program Files\Java\jdk1.8.0_111\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
echo Keystore created successfully!
pause 