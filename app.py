from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from db import query

app = Flask(__name__)
CORS(app)   # allows your HTML file (port 5500) to call Flask (port 5000)


@app.route("/")
def index():
    return send_from_directory(app.root_path, "HMS_Dashboard.html")

# ============================================================
# ROOMS
# ============================================================

@app.route("/api/rooms", methods=["GET"])
def get_rooms():
    """Q1 from your report: all rooms with class name and nightly rate."""
    rows = query("""
        SELECT r.room_id, r.room_number, r.floor_number,
               rc.class_name, rc.base_price AS nightly_rate,
               r.status, r.smoking, r.view_type, r.wheelchair_access, r.grab_bars
        FROM Room r
        JOIN Room_Class rc ON r.room_class_id = rc.room_class_id
        ORDER BY r.floor_number, r.room_number
    """)
    return jsonify(rows)


@app.route("/api/rooms", methods=["POST"])
def add_room():
    """Add a new room."""
    d = request.json
    # Look up class id from class name
    cls = query("SELECT room_class_id FROM Room_Class WHERE class_name = %s", (d["class_name"],))
    if not cls:
        return jsonify({"error": "Room class not found"}), 400
    class_id = cls[0]["room_class_id"]
    new_id = query("""
        INSERT INTO Room (room_class_id, room_number, floor_number, status,
                          smoking, view_type, wheelchair_access, grab_bars)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, (class_id, d["room_number"], d["floor_number"], d.get("status","Available"),
          d.get("smoking", False), d.get("view_type","Garden"),
          d.get("wheelchair_access", False), d.get("grab_bars", False)), fetch=False)
    return jsonify({"id": new_id, "message": "Room added"}), 201


@app.route("/api/rooms/<int:room_id>", methods=["PUT"])
def update_room(room_id):
    """Update room status or details."""
    d = request.json
    query("""
        UPDATE Room SET status = %s, view_type = %s, smoking = %s,
                        wheelchair_access = %s, grab_bars = %s
        WHERE room_id = %s
    """, (d.get("status"), d.get("view_type"), d.get("smoking", False),
          d.get("wheelchair_access", False), d.get("grab_bars", False), room_id), fetch=False)
    return jsonify({"message": "Room updated"})


@app.route("/api/rooms/<int:room_id>", methods=["DELETE"])
def delete_room(room_id):
    query("DELETE FROM Room WHERE room_id = %s", (room_id,), fetch=False)
    return jsonify({"message": "Room deleted"})


# ============================================================
# GUESTS
# ============================================================

@app.route("/api/guests", methods=["GET"])
def get_guests():
    rows = query("""
        SELECT p.person_id, CONCAT(p.first_name,' ',p.last_name) AS name,
               p.email, p.city, g.guest_type, g.loyalty_points
        FROM Guest g
        JOIN Person p ON g.person_id = p.person_id
        ORDER BY p.first_name
    """)
    return jsonify(rows)


@app.route("/api/guests", methods=["POST"])
def add_guest():
    d = request.json
    # Split name into first/last
    parts = d["name"].strip().split(" ", 1)
    first = parts[0]
    last = parts[1] if len(parts) > 1 else ""
    # Insert into Person first (supertype), then Guest (subtype)
    person_id = query(
        "INSERT INTO Person (first_name, last_name, email, city) VALUES (%s,%s,%s,%s)",
        (first, last, d["email"], d.get("city", "")), fetch=False)
    query(
        "INSERT INTO Guest (person_id, guest_type, loyalty_points) VALUES (%s,%s,0)",
        (person_id, d.get("guest_type","Regular")), fetch=False)
    return jsonify({"id": person_id, "message": "Guest added"}), 201


@app.route("/api/guests/<int:person_id>", methods=["DELETE"])
def delete_guest(person_id):
    references = query("""
        SELECT
            (SELECT COUNT(*) FROM Booking WHERE guest_id = %s) AS bookings,
            (SELECT COUNT(*) FROM Reservation WHERE guest_id = %s) AS reservations
    """, (person_id, person_id))[0]
    if references["bookings"] or references["reservations"]:
        return jsonify({
            "error": "Cannot delete a guest with existing bookings or reservations."
        }), 409
    # Delete Guest subtype first (FK constraint), then Person
    query("DELETE FROM Guest WHERE person_id = %s", (person_id,), fetch=False)
    query("DELETE FROM Person WHERE person_id = %s", (person_id,), fetch=False)
    return jsonify({"message": "Guest deleted"})


# ============================================================
# BOOKINGS  (uses your Q2 join logic)
# ============================================================

@app.route("/api/bookings", methods=["GET"])
def get_bookings():
    """Full booking history per guest with invoice details (your Q2)."""
    rows = query("""
        SELECT b.booking_id,
               CONCAT(p.first_name,' ',p.last_name) AS guest_name,
               g.guest_type,
               b.booking_date, b.status AS booking_status,
               b.num_adults, b.num_children,
               rc.class_name AS room_class,
               res.checkin_date, res.checkout_date,
               DATEDIFF(res.checkout_date, res.checkin_date) AS nights_stayed,
               rc.base_price * DATEDIFF(res.checkout_date, res.checkin_date) AS room_cost,
               i.invoice_id, i.total_amount, i.status AS invoice_status,
               COALESCE(SUM(pay.amount),0) AS amount_paid
        FROM Booking b
        JOIN Guest g ON b.guest_id = g.person_id
        JOIN Person p ON g.person_id = p.person_id
        JOIN Reservation res ON b.booking_id = res.booking_id
        JOIN Room_Class rc ON res.room_class_id = rc.room_class_id
        LEFT JOIN Invoice i ON b.booking_id = i.booking_id
        LEFT JOIN Payment pay ON i.invoice_id = pay.invoice_id AND pay.status = 'Completed'
        GROUP BY b.booking_id, p.first_name, p.last_name, g.guest_type,
                 b.booking_date, b.status, b.num_adults, b.num_children,
                 rc.class_name, res.checkin_date, res.checkout_date,
                 rc.base_price, i.invoice_id, i.total_amount, i.status
        ORDER BY b.booking_date DESC
    """)
    return jsonify(rows)


@app.route("/api/bookings", methods=["POST"])
def add_booking():
    d = request.json
    booking_id = query(
        """INSERT INTO Booking (guest_id, booking_date, num_adults, num_children, status)
           VALUES (%s, CURDATE(), %s, %s, 'Confirmed')""",
        (d["guest_id"], d.get("num_adults",1), d.get("num_children",0)), fetch=False)
    # Look up room class id
    cls = query("SELECT room_class_id, base_price FROM Room_Class WHERE class_name = %s",
                (d["room_class"],))
    if not cls:
        return jsonify({"error": "Room class not found"}), 400
    class_id = cls[0]["room_class_id"]
    # Create reservation
    query("""INSERT INTO Reservation (guest_id, room_class_id, booking_id,
                                      checkin_date, checkout_date, status)
             VALUES (%s,%s,%s,%s,%s,'Confirmed')""",
          (d["guest_id"], class_id, booking_id, d["checkin_date"], d["checkout_date"]),
          fetch=False)
    # Auto-generate invoice
    from datetime import datetime, timedelta
    nights = (datetime.strptime(d["checkout_date"],"%Y-%m-%d") -
              datetime.strptime(d["checkin_date"],"%Y-%m-%d")).days
    total = cls[0]["base_price"] * max(nights, 1)
    query("""INSERT INTO Invoice (booking_id, issued_date, due_date, total_amount, status)
             VALUES (%s, CURDATE(), %s, %s, 'Unpaid')""",
          (booking_id, d["checkout_date"], total), fetch=False)
    return jsonify({"id": booking_id, "message": "Booking created", "invoice_total": float(total)}), 201


@app.route("/api/bookings/<int:booking_id>/checkin", methods=["PUT"])
def checkin(booking_id):
    query("UPDATE Booking SET status='Checked-In' WHERE booking_id=%s", (booking_id,), fetch=False)
    query("UPDATE Reservation SET status='Checked-In' WHERE booking_id=%s", (booking_id,), fetch=False)
    return jsonify({"message": "Checked in"})


@app.route("/api/bookings/<int:booking_id>/checkout", methods=["PUT"])
def checkout(booking_id):
    query("UPDATE Booking SET status='Checked-Out' WHERE booking_id=%s", (booking_id,), fetch=False)
    query("UPDATE Reservation SET status='Checked-Out' WHERE booking_id=%s", (booking_id,), fetch=False)
    return jsonify({"message": "Checked out"})


# ============================================================
# PAYMENTS
# ============================================================

@app.route("/api/payments", methods=["GET"])
def get_payments():
    """Payment summary per invoice (your Q10)."""
    rows = query("""
        SELECT pay.payment_id,
               CONCAT(p.first_name,' ',p.last_name) AS guest_name,
               pay.payment_date, pay.amount, pay.payment_method, pay.status,
               i.invoice_id, i.total_amount
        FROM Payment pay
        JOIN Invoice i ON pay.invoice_id = i.invoice_id
        JOIN Booking b ON i.booking_id = b.booking_id
        JOIN Guest g ON b.guest_id = g.person_id
        JOIN Person p ON g.person_id = p.person_id
        ORDER BY pay.payment_date DESC
    """)
    return jsonify(rows)


@app.route("/api/payments", methods=["POST"])
def add_payment():
    d = request.json
    payment_id = query(
        """INSERT INTO Payment (invoice_id, payment_date, amount, payment_method, status)
           VALUES (%s, CURDATE(), %s, %s, 'Completed')""",
        (d["invoice_id"], d["amount"], d["payment_method"]), fetch=False)
    # Update invoice status
    query("""UPDATE Invoice SET status =
               CASE WHEN (SELECT COALESCE(SUM(amount),0) FROM Payment
                          WHERE invoice_id=%s AND status='Completed') >= total_amount
                    THEN 'Paid' ELSE 'Partially Paid' END
             WHERE invoice_id=%s""",
          (d["invoice_id"], d["invoice_id"]), fetch=False)
    return jsonify({"id": payment_id, "message": "Payment recorded"}), 201


# ============================================================
# REPORTS
# ============================================================

@app.route("/api/reports/revenue", methods=["GET"])
def revenue_by_class():
    """Your Q4: revenue grouped by room class."""
    rows = query("""
        SELECT rc.class_name,
               COUNT(DISTINCT b.booking_id) AS total_bookings,
               SUM(DATEDIFF(res.checkout_date, res.checkin_date)) AS total_nights,
               SUM(rc.base_price * DATEDIFF(res.checkout_date, res.checkin_date)) AS room_revenue
        FROM Booking b
        JOIN Reservation res ON b.booking_id = res.booking_id
        JOIN Room_Class rc ON res.room_class_id = rc.room_class_id
        WHERE b.status IN ('Checked-In','Checked-Out')
        GROUP BY rc.class_name
        ORDER BY room_revenue DESC
    """)
    return jsonify(rows)


@app.route("/api/reports/defaulters", methods=["GET"])
def defaulters():
    """Your Q5: guests with outstanding balance."""
    rows = query("""
        SELECT CONCAT(p.first_name,' ',p.last_name) AS guest_name,
               p.email, b.booking_id, i.invoice_id, i.total_amount,
               COALESCE(SUM(pay.amount),0) AS amount_paid,
               (i.total_amount - COALESCE(SUM(pay.amount),0)) AS outstanding_balance,
               i.due_date
        FROM Invoice i
        JOIN Booking b ON i.booking_id = b.booking_id
        JOIN Guest g ON b.guest_id = g.person_id
        JOIN Person p ON g.person_id = p.person_id
        LEFT JOIN Payment pay ON i.invoice_id = pay.invoice_id AND pay.status='Completed'
        WHERE b.status = 'Checked-Out'
        GROUP BY i.invoice_id, p.first_name, p.last_name, p.email,
                 b.booking_id, i.total_amount, i.due_date
        HAVING outstanding_balance > 0
        ORDER BY outstanding_balance DESC
    """)
    return jsonify(rows)


@app.route("/api/reports/occupancy", methods=["GET"])
def occupancy():
    """Your Q6: room occupancy by floor."""
    rows = query("""
        SELECT floor_number,
               COUNT(room_id) AS total_rooms,
               SUM(CASE WHEN status='Occupied' THEN 1 ELSE 0 END) AS occupied,
               SUM(CASE WHEN status='Available' THEN 1 ELSE 0 END) AS available,
               ROUND(SUM(CASE WHEN status='Occupied' THEN 1 ELSE 0 END)*100.0/COUNT(room_id),1) AS occupancy_pct
        FROM Room
        GROUP BY floor_number
        ORDER BY floor_number
    """)
    return jsonify(rows)


@app.route("/api/reports/addon-revenue", methods=["GET"])
def addon_revenue():
    """Your Q7: revenue per add-on service."""
    rows = query("""
        SELECT a.addon_name,
               SUM(ba.quantity) AS total_units_sold,
               SUM(ba.quantity * ba.unit_price) AS total_addon_revenue
        FROM Booking_Addon ba
        JOIN Addon a ON ba.addon_id = a.addon_id
        GROUP BY a.addon_name
        ORDER BY total_addon_revenue DESC
    """)
    return jsonify(rows)


# ============================================================
# STAFF
# ============================================================

@app.route("/api/staff", methods=["GET"])
def get_staff():
    rows = query("""
        SELECT p.person_id, CONCAT(p.first_name,' ',p.last_name) AS name,
               p.email, s.position, s.salary, s.hire_date
        FROM Staff s
        JOIN Person p ON s.person_id = p.person_id
        ORDER BY s.hire_date
    """)
    return jsonify(rows)


@app.route("/api/staff", methods=["POST"])
def add_staff():
    d = request.json
    parts = d["name"].strip().split(" ", 1)
    first = parts[0]
    last = parts[1] if len(parts) > 1 else ""
    person_id = query(
        "INSERT INTO Person (first_name, last_name, email) VALUES (%s,%s,%s)",
        (first, last, d["email"]), fetch=False)
    query(
        "INSERT INTO Staff (person_id, position, salary, hire_date) VALUES (%s,%s,%s,CURDATE())",
        (person_id, d["position"], d["salary"]), fetch=False)
    return jsonify({"id": person_id, "message": "Staff added"}), 201


@app.route("/api/staff/<int:person_id>", methods=["DELETE"])
def delete_staff(person_id):
    query("DELETE FROM Staff WHERE person_id=%s", (person_id,), fetch=False)
    query("DELETE FROM Person WHERE person_id=%s", (person_id,), fetch=False)
    return jsonify({"message": "Staff deleted"})


# ============================================================
# DASHBOARD SUMMARY
# ============================================================

@app.route("/api/dashboard", methods=["GET"])
def dashboard():
    total_rooms = query("SELECT COUNT(*) AS n FROM Room")[0]["n"]
    available = query("SELECT COUNT(*) AS n FROM Room WHERE status='Available'")[0]["n"]
    occupied = query("SELECT COUNT(*) AS n FROM Room WHERE status='Occupied'")[0]["n"]
    active_bookings = query(
        "SELECT COUNT(*) AS n FROM Booking WHERE status IN ('Confirmed','Checked-In')"
    )[0]["n"]
    total_revenue = query(
        "SELECT COALESCE(SUM(amount),0) AS n FROM Payment WHERE status='Completed'"
    )[0]["n"]
    defaulter_count = query("""
        SELECT COUNT(DISTINCT b.booking_id) AS n
        FROM Booking b
        JOIN Invoice i ON b.booking_id = i.booking_id
        LEFT JOIN Payment pay ON i.invoice_id = pay.invoice_id AND pay.status='Completed'
        WHERE b.status='Checked-Out'
        GROUP BY i.invoice_id, i.total_amount
        HAVING (i.total_amount - COALESCE(SUM(pay.amount),0)) > 0
    """)
    return jsonify({
        "total_rooms": total_rooms,
        "available_rooms": available,
        "occupied_rooms": occupied,
        "active_bookings": active_bookings,
        "total_revenue": float(total_revenue),
        "defaulter_count": len(defaulter_count)
    })


# ============================================================
# RUN
# ============================================================
if __name__ == "__main__":
    print("HMS Backend running at http://localhost:5000")
    print("Open HMS_Dashboard.html with Live Server to see the UI")
    app.run(debug=True, port=5000)
