@echo off
echo Creating keystore for FocusLock...
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass focuslock123 -keypass focuslock123 -dname "CN=FocusLock, OU=Development, O=Kiet Hoang Duong, L=Vietnam, S=Vietnam, C=VN"
echo Keystore created successfully!
pause