### Requirement: No external avatar generation URL

The system MUST NOT use `api.multiavatar.com` or any other external avatar-generation service as a fallback for user, mixin network user, or NFT collection avatars.

#### Scenario: User without uploaded or OAuth avatar

- **WHEN** a user has no ActiveStorage avatar and no OAuth `avatar_url`
- **THEN** `User#avatar_image_url` returns `nil`
- **AND** no multiavatar URL is constructed

#### Scenario: Mixin network user without OAuth avatar

- **WHEN** a `MixinNetworkUser` has no `raw["avatar_url"]`
- **THEN** its avatar method returns the platform icon asset URL instead of a multiavatar URL

### Requirement: Frontend initials placeholder

The system SHALL render a default avatar placeholder in the web UI consisting of the user's initials on a deterministic background color when no real avatar image URL exists.

#### Scenario: Latin name placeholder

- **WHEN** a user named "Test Author" has no real avatar image
- **THEN** the avatar partial renders a circle displaying "TA"
- **AND** the background color is deterministically derived from the user's `mixin_uuid`

#### Scenario: Single-word Latin name

- **WHEN** a user named "Alice" has no real avatar image
- **THEN** the avatar partial renders a circle displaying "A"

#### Scenario: CJK name placeholder

- **WHEN** a user named "张三" has no real avatar image
- **THEN** the avatar partial renders a circle displaying "张"

#### Scenario: Real avatar takes precedence

- **WHEN** a user has an ActiveStorage avatar attached
- **THEN** the avatar partial renders an `<img>` with the storage URL
- **AND** no initials placeholder is shown

#### Scenario: OAuth avatar takes precedence

- **WHEN** a user has no ActiveStorage avatar but has an OAuth `avatar_url`
- **THEN** the avatar partial renders an `<img>` with the OAuth URL
- **AND** no initials placeholder is shown

### Requirement: Deterministic color from seed

The placeholder background color MUST be deterministically computed from the user's `mixin_uuid` so the same user always receives the same color.

#### Scenario: Stable color per user

- **WHEN** the avatar placeholder is rendered twice for the same user
- **THEN** both renderings produce the same background color

#### Scenario: Different users different colors

- **WHEN** two users with different `mixin_uuid` values have no real avatar
- **THEN** their placeholder background colors SHOULD differ in most cases

### Requirement: External context static fallback

Server contexts that require a fetchable image URL MUST fall back to the platform icon asset when no real avatar image exists.

#### Scenario: Mixin bot notification icon

- **WHEN** a notifier sends an `icon_url` for a user without a real avatar
- **THEN** the URL points to the platform icon asset (e.g. `icon.png`)
- **AND** the URL is fetchable over HTTP

#### Scenario: Share to Mixin icon

- **WHEN** a share action includes `icon_url` for a user without a real avatar
- **THEN** the URL points to the platform icon asset

### Requirement: API avatar fields

JSON API responses for authors MUST expose avatar state explicitly when no real image exists.

#### Scenario: Author with real avatar in API

- **WHEN** an API response includes an author with an uploaded or OAuth avatar
- **THEN** `avatar` contains the image URL
- **AND** `avatar_seed` and `avatar_initials` are present for client convenience

#### Scenario: Author without real avatar in API

- **WHEN** an API response includes an author without a real avatar
- **THEN** `avatar` is `null`
- **AND** `avatar_seed` contains the author's `mixin_uuid`
- **AND** `avatar_initials` contains the computed initials string

### Requirement: Shared avatar rendering

The web UI MUST use a single shared avatar partial for all user avatar renderings instead of direct `image_tag user.avatar_url` calls.

#### Scenario: Consistent partial usage

- **WHEN** any ERB view displays a user avatar
- **THEN** it renders via the shared avatar partial
- **AND** sizing is controlled via a passed CSS class local
