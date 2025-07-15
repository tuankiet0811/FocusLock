@echo off
echo Creating keystore for FocusLock with default password...
echo focuslock123 | "C:\Program Files\Java\jdk1.8.0_111\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass focuslock123 -keypass focuslock123 -dname "CN=FocusLock, OU=Development, O=Kiet Hoang Duong, L=Vietnam, S=Vietnam, C=VN"
echo Keystore created successfully!
pause 