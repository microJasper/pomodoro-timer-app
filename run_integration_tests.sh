#!/bin/bash

echo "🚀 Pomodoro Timer App - Integration Test Runner"
echo "================================================"
echo ""

# Test dosyalarının yolları
HOME_TEST="integration_test/home_screen_test.dart"
STATS_TEST="integration_test/statistics_screen_test.dart"
SETTINGS_TEST="integration_test/settings_screen_test.dart"
APP_FLOW_TEST="integration_test/app_flow_test.dart"

# Cihaz seçimi
echo "📱 Available devices:"
flutter devices

echo ""
echo "🎯 Running Integration Tests on Chrome (Web)..."
echo ""

# Test 1: Home Screen Tests
echo "1️⃣ Running Home Screen Tests..."
flutter test $HOME_TEST -d chrome --reporter expanded
HOME_RESULT=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 2: Statistics Screen Tests
echo "2️⃣ Running Statistics Screen Tests..."
flutter test $STATS_TEST -d chrome --reporter expanded
STATS_RESULT=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 3: Settings Screen Tests
echo "3️⃣ Running Settings Screen Tests..."
flutter test $SETTINGS_TEST -d chrome --reporter expanded
SETTINGS_RESULT=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 4: App Flow Tests
echo "4️⃣ Running App Flow Tests..."
flutter test $APP_FLOW_TEST -d chrome --reporter expanded
FLOW_RESULT=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Sonuçları göster
echo "📊 TEST RESULTS SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $HOME_RESULT -eq 0 ]; then
    echo "✅ Home Screen Tests: PASSED"
else
    echo "❌ Home Screen Tests: FAILED"
fi

if [ $STATS_RESULT -eq 0 ]; then
    echo "✅ Statistics Screen Tests: PASSED"
else
    echo "❌ Statistics Screen Tests: FAILED"
fi

if [ $SETTINGS_RESULT -eq 0 ]; then
    echo "✅ Settings Screen Tests: PASSED"
else
    echo "❌ Settings Screen Tests: FAILED"
fi

if [ $FLOW_RESULT -eq 0 ]; then
    echo "✅ App Flow Tests: PASSED"
else
    echo "❌ App Flow Tests: FAILED"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Toplam başarı kontrolü
TOTAL_FAILURES=$((HOME_RESULT + STATS_RESULT + SETTINGS_RESULT + FLOW_RESULT))

if [ $TOTAL_FAILURES -eq 0 ]; then
    echo "🎉 ALL INTEGRATION TESTS PASSED!"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    exit 1
fi
