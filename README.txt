=====================================================
  Hotel Management System — University of Malakand
  Group Leader: Usman Khan
  Members: Syed Hamza, Shah Islam, Zaid Ferman
  Instructor: Dr. Shah Khalid | June 2026
=====================================================

FILES IN THIS PROJECT:
-----------------------
  HMS_Dashboard.html          → Frontend (open with Live Server in VS Code)
  app.py                      → Flask backend (REST API)
  db.py                       → MySQL connection helper
  HMS_SQL_Implementation.sql  → Your database schema + sample data
  requirements.txt            → Python packages needed
  .env                        → Local database credentials (never commit)
  .env.example                → Safe template for local configuration

STEP-BY-STEP SETUP:
--------------------

STEP 1 — Install Python packages
  Open terminal in VS Code and run:
    pip install -r requirements.txt

STEP 2 — Set up MySQL database
  Open MySQL Workbench → File → Open SQL Script → select HMS_SQL_Implementation.sql
  Click the lightning bolt ⚡ to run it.
  This creates the hotel_management_db with all 15 tables + sample data.

STEP 3 — Configure your MySQL password
  Copy .env.example to .env, then set DB_USER and DB_PASSWORD in .env.
  The .env file is ignored by Git and must never be committed.
  If your password is blank, leave DB_PASSWORD empty.

STEP 4 — Run the Flask backend
  In VS Code terminal:
    python app.py
  You will see: "HMS Backend running at http://localhost:5000"
  KEEP THIS TERMINAL OPEN.

STEP 5 — Open the dashboard
  Visit: http://localhost:5000/
  Flask serves HMS_Dashboard.html at this address.

STEP 6 — Verify it works
  Visit in browser: http://localhost:5000/api/rooms
  You should see JSON data from your MySQL database.

NOTE: The dashboard works even WITHOUT Flask running.
  It automatically detects if Flask is available.
  If Flask is not running → Demo Mode (sample data, no database).
  If Flask is running    → Live Mode (real MySQL data, full CRUD).

API ENDPOINTS (Flask):
-----------------------
  GET  /api/dashboard           → Stats summary
  GET  /api/rooms               → All rooms
  POST /api/rooms               → Add room
  DEL  /api/rooms/<id>          → Delete room
  GET  /api/guests              → All guests
  POST /api/guests              → Add guest
  DEL  /api/guests/<id>         → Delete guest
  GET  /api/bookings            → All bookings (Q2 from report)
  POST /api/bookings            → Create booking + auto invoice
  PUT  /api/bookings/<id>/checkin   → Check in
  PUT  /api/bookings/<id>/checkout  → Check out
  GET  /api/payments            → All payments (Q10)
  POST /api/payments            → Record payment
  GET  /api/staff               → All staff
  POST /api/staff               → Add staff
  DEL  /api/staff/<id>          → Delete staff
  GET  /api/reports/revenue     → Revenue by class (Q4)
  GET  /api/reports/defaulters  → Defaulter list (Q5)
  GET  /api/reports/occupancy   → Occupancy by floor (Q6)
  GET  /api/reports/addon-revenue → Add-on revenue (Q7)

=====================================================

SECURITY NOTE:
  If database credentials were already pushed to GitHub, changing .gitignore
  does not remove them from Git history. Change the MySQL password, then
  update your local .env file with the new password.
