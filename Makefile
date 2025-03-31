.PHONY: run-flutter run-python test

run-flutter:
	flutter run -d chrome

run-python:
	cd backend && python3 -m core.sotr_calculator

test:
	flutter test
