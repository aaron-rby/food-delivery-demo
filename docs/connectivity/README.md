# JDBC connectivity and commands

```text
Browser → local Java HTTP server → FoodService → Oracle JDBC → FOOD_PROJECT
```

The HTTP server runs on loopback port 8788. It serves `frontend/` and exposes `/api`. Oracle normally listens on local port 1521 in the recorded XE installation. These are different ports for different services.

## 1. Configure the driver and connection

Copy a suitable Oracle JDBC driver to `backend/lib/ojdbc6.jar`. The original local driver is at `C:\oraclexe\app\oracle\product\11.2.0\server\jdbc\lib\ojdbc6.jar`; installations can differ. You may instead use another compatible Oracle driver and update the runtime classpath.

```powershell
New-Item -ItemType Directory -Force lib
Copy-Item 'C:\oraclexe\app\oracle\product\11.2.0\server\jdbc\lib\ojdbc6.jar' backend/lib/ojdbc6.jar
Copy-Item backend/config/database.example.properties backend/config/database.properties
```

Edit `backend/config/database.properties` locally:

```properties
url=jdbc:oracle:thin:@localhost:1521:XE
user=FOOD_PROJECT
password=YOUR_LOCAL_PASSWORD
```

For a database service instead of an SID, use a suitable service URL such as `jdbc:oracle:thin:@//localhost:1521/your_service`. Never commit your real configuration file.

## 2. Compile from the repository root

```powershell
New-Item -ItemType Directory -Force build
javac -d build backend/FoodService.java backend/WebServer.java backend/tests/Phase2Test.java
```

## 3. Start the backend and front end together

```powershell
java -cp "build;backend/lib/ojdbc6.jar" WebServer backend/config/database.properties
```

Keep the terminal open and visit http://127.0.0.1:8788. The terminal should print `Oracle JDBC connected.` The Windows shortcut is `backend/scripts/start.cmd`.

On macOS/Linux, replace the semicolon between classpath entries with a colon: `-cp "build:backend/lib/ojdbc6.jar"`.

## 4. Run integration tests

```powershell
java -cp "build;backend/lib/ojdbc6.jar" Phase2Test backend/config/database.properties
```

The test runner creates temporary records and removes its own records afterward. It restores the sampled menu price and checks original row counts. Run it against the project/test schema, not unrelated data.

## What the backend does

- `DriverManager.getConnection` opens the Oracle JDBC connection.
- `PreparedStatement` binds values separately from SQL text.
- `setAutoCommit(false)` groups related writes into transactions.
- `commit()` completes successful operations; `rollback()` cancels failed operations.
- `placeOrder` reads/locks menu rows, captures prices and inserts header, lines and pending payment together.
- `advance`, `assign`, `dispatch`, `pay` and `deliver` enforce preparation/delivery rules.
- HTTP GET `/api` retrieves the state; HTTP POST `/api` dispatches a validated operation.

The browser never receives the Oracle password. Demo role selection is not an authentication system.
