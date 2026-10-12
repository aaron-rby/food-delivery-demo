# Java backend

`WebServer.java` serves the browser UI and exposes `/api`. `FoodService.java` connects to Oracle through JDBC and applies validation, transactions, row locks and workflow rules. See the main README's **Java backend** section for an explanation of both files.

From the repository root:

```powershell
backend/scripts/build.cmd
backend/scripts/start.cmd
backend/scripts/test.cmd
```

Place the compatible JDBC driver in `backend/lib/ojdbc6.jar`. Copy `backend/config/database.example.properties` to `backend/config/database.properties` and edit your credentials locally. Do not commit the real configuration.

The ordinary integration suite is `tests/Phase2Test.java`. `tests/RoleReview.java` additionally checks existing-partner → Both, role-preserving removals and history protection inside a transaction that is rolled back. It can be compiled with the service and run with your local properties file; Oracle sequence values may advance during testing.

Java receives all writes through the HTTP adapter. UI role selection is not authentication or an API permission check.
