<!-- hash: 627 -->
API::ValidUsersController < API::BaseController
- filter: GET /api/valid_user_filter?user_id=<Mixin UUID>&type=recent
- Finds user by mixin_uuid. If blank, approved=false.
- type="recent": checks payments sum > 0 or published articles > 0 in past week
- Otherwise: checks any payments sum > 0 or any published articles > 0
- Returns: {"approved": true/false}