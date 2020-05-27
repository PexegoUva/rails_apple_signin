## 0.3.0
* Improvements
  * Improved test battery to better check if keys used to sign Apple identity token are correct or not.

* Bugfix
  * Return nil instead of public keys, when there is no valid public key.

## 0.2.0

* Additions
  * Added method `validate` to check integrity of provided Apple token by returning information inside the token as payload.
  * Add rubygems version badge.
  * Add Travis config file for CI.
  * Add build badge.

* Improvemens
  * Added break in case payload is retrieved successfully in any iteration to avoid more of them.

## 0.1.0

* Additions
  * Beta release