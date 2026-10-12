# Savour

A public, black-and-white browser demo for a Database Systems course project.

Choose Customer, Partners or Admin in the header. Customers browse restaurants and see their own orders. Partners see only their assigned deliveries. Admin manages menus, preparation and partner assignment. Meera Shah has both customer and delivery partner roles.

Customer view has an **Add customer** button; Partners view has **Add delivery partner**. The form lets you select Customer, Delivery partner or Both, create a named person, or add roles to an existing person. Both uses one ID across the two roles. IDs identify people even when names match. This is a demonstration role selector without login, so it does not enforce access permissions.

**Shared demonstration:** `backend-config.js` points to a temporary HTTPS tunnel to the local Java/Oracle backend. Visitors share database records while the computer, Oracle, Java server and tunnel are running. Views refresh every five seconds when no form is being edited. There is no login: roles are demonstration filters, not permissions. Use fictional information and simulated payments only.

When the shared server is offline, saving is disabled and the UI retries every five seconds. Existing browser-only orders are not automatically uploaded. Clearing the API URL restores the separate localStorage demo. A restarted Quick Tunnel receives a new URL; update backend-config.js and publish it.

The full Java/JDBC/Oracle project remains in a separate private repository. This public repository contains only the demo's HTML, CSS and JavaScript.

## Run locally

```powershell
python -m http.server 8790 --bind 127.0.0.1
```

Open http://127.0.0.1:8790. There are no frontend build dependencies.

## Demonstration

Admin's **Menu management** has a restaurant dropdown. Select a restaurant to edit only its dishes. **Add food** creates a named dish with a category, price and availability. **Add restaurant** collects its name, address, city, postal code and optional phone, then selects it so you can add food. Existing visitors receive six extra fictional customers and ten extra dishes without losing saved orders or edited prices.

1. Choose Asha Rao and Campus Kitchen.
2. Add two Veg Rice and one Juice. The total is INR 350 including the delivery fee.
3. Enter a fictional destination and place the order.
4. Choose Admin and mark the new order accepted, preparing, then ready.
5. In Admin, assign an available partner.
6. Choose Partners, select that partner, record pickup and simulated payment, then mark delivered.

Online orders require simulated successful payment before pickup. Delivery completion requires successful payment. You can inspect historical prices by changing a current menu price after placing an order.
