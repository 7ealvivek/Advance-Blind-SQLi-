# Advance-Blind-SQLi-
Use it very sincerely 💀 for education purposes only.

Key Features:

	1.	Advanced Payloads: The script includes 30 advanced blind SQL injection payloads designed to induce a 10-second delay.
	2.	GET and POST Testing: It tests for vulnerabilities using both GET and POST methods.
	3.	Results Logging: Vulnerable URLs are logged to results.txt.

Usage Instructions:

	1.	Prepare Your Subdomains List: Create a file named subs.txt containing your live subdomains, one subdomain per line.
	2.	Save the Script: Copy the script above into a file named sqli_tester.sh.
	3.	Make the Script Executable:
 chmod +x sqli_tester.sh

 4.	Run the Script for a Single Domain:

./sqli_tester.sh -d example.com


	5.	Run the Script for Multiple Domains:

./sqli_tester.sh -l subs.txt


	6.	Run the Script with Custom Payloads:

./sqli_tester.sh -d example.com -p "your_custom_payload1,your_custom_payload2"



MUST HAVE THESE TOOL IN GO PATH
gau| gauplus | katana | hakrawler
