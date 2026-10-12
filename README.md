# Savour

A public, black-and-white browser demo for a Database Systems course project.

Choose Customer, Partners or Admin in the header. Customers browse restaurants and see their own orders. Partners see only their assigned deliveries. Admin manages menus, preparation and partner assignment. Meera Shah has both customer and delivery partner roles.

Customer view has an **Add customer** button; Partners view has **Add delivery partner**. Create a named person or add a role to an existing person. IDs identify people even when names match. This is a demonstration role selector without login, so it does not enforce access permissions.

**This site uses fictional sample data stored in your browser's localStorage.** It does not connect to Oracle or a shared backend, and it does not process real payments. Changes made by one visitor do not appear in another visitor's browser.

The full Java/JDBC/Oracle project remains in a separate private repository. This public repository contains only the demo's HTML, CSS and JavaScript.

## Run locally

```powershell
python -m http.server 8790 --bind 127.0.0.1
```

Open http://127.0.0.1:8790. There are no frontend build dependencies.

## Demonstration

1. Choose Asha Rao and Campus Kitchen.
2. Add two Veg Rice and one Juice. The total is INR 350 including the delivery fee.
3. Enter a fictional destination and place the order.
4. Choose Admin and mark the new order accepted, preparing, then ready.
5. In Admin, assign an available partner.
6. Choose Partners, select that partner, record pickup and simulated payment, then mark delivered.

Online orders require simulated successful payment before pickup. Delivery completion requires successful payment. You can inspect historical prices by changing a current menu price after placing an order.
