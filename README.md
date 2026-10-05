# 🏨 Hotel Management System

A database-driven **Hotel Management System (HMS)** developed to manage core hotel operations through a web-based application. The system uses a **Python/Flask backend**, **MySQL relational database**, and an interactive **HTML, CSS, and JavaScript dashboard**.

The application provides REST-style API endpoints for managing hotel data and connects the frontend with the relational database through the Flask backend.

---

## 📌 Project Overview

The Hotel Management System provides a centralized platform for managing important hotel operations, including:

- 👤 Guest management
- 👨‍💼 Staff management
- 🛏️ Room management
- 📅 Booking management
- 🏨 Reservations
- 💳 Payments and invoices
- 🛎️ Add-on services
- 📊 Hotel reports
- 📈 Dashboard statistics
- 🗄️ Relational database management

The project demonstrates practical implementation of **Database Management System (DBMS)** concepts together with a web-based application.

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| **Python** | Backend application development |
| **Flask** | Web framework and API development |
| **REST-style API** | Communication between frontend and backend |
| **MySQL** | Relational database management |
| **SQL** | Database operations and queries |
| **HTML5** | Frontend structure |
| **CSS3** | User interface styling |
| **JavaScript** | Frontend functionality and API communication |

---

## 🏗️ System Architecture

```text
                 HOTEL MANAGEMENT SYSTEM
                          │
             ┌────────────┴────────────┐
             │                         │
         FRONTEND                    BACKEND
             │                         │
    HTML + CSS + JavaScript      Python + Flask
             │                         │
             └────────────┬────────────┘
                          │
                   REST-style API
                          │
                          ▼
                         SQL
                          │
                          ▼
                        MySQL
                       DATABASE
```

---

## 🔄 How the System Works

The frontend dashboard communicates with the Flask backend through API endpoints.

For example:

```text
Frontend
   │
   │ GET /api/rooms
   ▼
Flask Backend
   │
   │ SQL Query
   ▼
MySQL Database
   │
   │ Results
   ▼
Flask Backend
   │
   │ JSON Response
   ▼
Frontend Dashboard
```

The backend uses Flask routes such as:

- `GET /api/rooms`
- `POST /api/rooms`
- `PUT /api/rooms/<room_id>`
- `DELETE /api/rooms/<room_id>`
- `GET /api/guests`
- `POST /api/guests`
- `GET /api/bookings`
- `POST /api/bookings`
- `GET /api/payments`
- `POST /api/payments`
- `GET /api/dashboard`

These endpoints use JSON requests and responses to exchange data between the frontend and backend.

---

## 🗄️ Database

The system uses **MySQL** as its relational database.

The database design includes entities and relationships for:

- Person
- Guest
- Staff
- Room
- Room Class
- Booking
- Reservation
- Invoice
- Payment
- Add-on services
- Related hotel information

The project applies important database concepts including:

- Primary Keys
- Foreign Keys
- Referential Integrity
- Entity Relationships
- One-to-One Relationships
- One-to-Many Relationships
- Many-to-Many Relationships
- Associative Entities
- Generalization and Specialization
- Normalization
- SQL Queries
- Database Constraints

---

## 📂 Project Structure

```text
Hotel-Management-System/
│
├── app.py
├── db.py
├── HMS_SQL_Implementation.sql
├── HMS_Dashboard.html
├── hms_project_changes.csv
├── requirements.txt
├── .env.example
├── README.md
└── README.txt
```

### `app.py`

Contains the Flask backend and API endpoints for rooms, guests, bookings, payments, reports, staff, and dashboard statistics.

### `db.py`

Handles communication between the Flask application and the MySQL database.

### `HMS_SQL_Implementation.sql`

Contains the SQL implementation of the hotel management database.

### `HMS_Dashboard.html`

Provides the web-based dashboard interface.

### `requirements.txt`

Contains the Python dependencies required to run the application.

### `.env.example`

Provides an example structure for environment-based configuration.

---

## ⚙️ Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/usmankhan-pro/Hotel-Management-System.git
```

### 2. Open the Project

```bash
cd Hotel-Management-System
```

### 3. Create a Virtual Environment

```bash
python -m venv .venv
```

### 4. Activate the Virtual Environment

**Windows PowerShell:**

```powershell
.venv\Scripts\Activate.ps1
```

**Windows Command Prompt:**

```cmd
.venv\Scripts\activate
```

### 5. Install Dependencies

```bash
pip install -r requirements.txt
```

### 6. Configure MySQL

Create the required MySQL database and execute:

```text
HMS_SQL_Implementation.sql
```

Configure the database connection using the project's environment configuration.

### 7. Start the Flask Backend

```bash
python app.py
```

The backend runs on:

```text
http://localhost:5000
```

### 8. Open the Dashboard

The application is designed to use the dashboard with a local web server such as **VS Code Live Server**.

---

## 🔐 Environment Configuration

Database credentials and other configuration values should not be hard-coded or committed publicly.

Use environment variables for sensitive configuration and keep the actual `.env` file private.

The repository provides:

```text
.env.example
```

as a configuration reference.

---

## 🎯 Project Objectives

The main objectives of the Hotel Management System are to:

- Digitize hotel management operations.
- Maintain organized customer and hotel records.
- Improve room and booking management.
- Reduce manual record-management problems.
- Provide efficient access to hotel information.
- Apply relational database design principles.
- Implement SQL-based data management.
- Develop a functional web-based database application.
- Demonstrate integration between a frontend, backend, and relational database.

---

## 📊 System Features

### 👤 Guest Management

- View guest information
- Add new guests
- Delete guests
- Maintain guest types and loyalty information

### 🛏️ Room Management

- View available rooms
- Add rooms
- Update room information
- Delete rooms
- Manage room status and characteristics

### 📅 Booking & Reservation Management

- Create bookings
- View booking history
- Check guests in
- Check guests out
- Manage reservation information

### 💳 Payment & Invoice Management

- Record payments
- Track invoice status
- Calculate outstanding balances
- Generate payment-related information

### 📈 Reports

The system provides reports including:

- Revenue by room class
- Guest outstanding balances
- Room occupancy
- Add-on service revenue

### 📊 Dashboard

The dashboard provides summary information such as:

- Total rooms
- Available rooms
- Occupied rooms
- Active bookings
- Total revenue
- Outstanding/defaulting bookings

---

## 🎓 Academic Context

This project was developed as part of the **Database Systems** course at the **University of Malakand**.

**Project:** Hotel Management Database System  
**Course:** Database Systems  
**Institution:** University of Malakand

---

## 👥 Project Team

- **Usman Khan**
- **Syed Humaz**

---

## 🚀 Future Improvements

Potential future improvements include:

- User authentication
- Role-based access control
- Online booking
- Advanced reporting and analytics
- Enhanced dashboard visualizations
- Email notifications
- Payment gateway integration
- Cloud deployment
- Additional security and validation

---

## 📄 License

This project is developed for **academic and educational purposes**.

---

⭐ **If you find this project useful, consider giving the repository a star.**
