# b1tza administrator setup

The account designated for Paul is **b1tza**. This repository does not contain a live server account database or passwords, so copying these files alone does not grant live access.

1. Use the MTA server console to create the account before opening registration to the public: `addaccount b1tza YOUR_STRONG_PASSWORD`. Do not commit the password.
2. Stop the server and back up its existing `mods/deathmatch/acl.xml`.
3. In the existing `Admin` group, add `<object name="user.b1tza" />` and `<object name="resource.e_admin" />`. The fragment in `admin-b1tza.xml` shows the entries; merge them rather than replacing the full ACL or adding a second Admin group. Retain the other existing entries.
4. Start the server, sign in using the **account name** `b1tza`, and press the admin panel key (default O). A player nickname alone does not confer access.

`dayzepoch` and `e_login` still need the resource ACL rights documented in the main README. The admin panel now checks the authenticated caller's Admin ACL membership for every action. The legacy `admin` element-data bypass has been removed.
