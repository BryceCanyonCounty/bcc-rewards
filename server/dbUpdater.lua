CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewardcodes` (
            `code` VARCHAR(50) NOT NULL,
            `maxUse` INT(11) NOT NULL DEFAULT 0 COMMENT '-1 = infinite use',
            `currentUse` INT(10) UNSIGNED NOT NULL DEFAULT 0,
            `active` INT(1) NOT NULL DEFAULT 1,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `expires_at` DATETIME DEFAULT NULL,
            PRIMARY KEY (`code`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewardcodes_items` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `code` VARCHAR(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
            `item` VARCHAR(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
            `quantity` INT(11) NOT NULL DEFAULT 1,
            PRIMARY KEY (`id`),
            KEY `bcc_rc_items_code_fk` (`code`),
            KEY `bcc_rc_items_item_fk` (`item`),
            CONSTRAINT `bcc_rc_items_code_fk` FOREIGN KEY (`code`) REFERENCES `bcc_rewardcodes` (`code`) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT `bcc_rc_items_item_fk` FOREIGN KEY (`item`) REFERENCES `items` (`item`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewardcodes_money` (
            `code` VARCHAR(50) NOT NULL,
            `money` INT(11) NOT NULL DEFAULT 0,
            `gold` INT(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (`code`),
            CONSTRAINT `bcc_rc_money_code_fk` FOREIGN KEY (`code`) REFERENCES `bcc_rewardcodes` (`code`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewardcodes_users` (
            `identifier` VARCHAR(50) NOT NULL,
            `code` VARCHAR(50) NOT NULL,
            `redeemed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`, `code`),
            KEY `bcc_rc_users_code_fk` (`code`),
            CONSTRAINT `bcc_rc_users_code_fk` FOREIGN KEY (`code`) REFERENCES `bcc_rewardcodes` (`code`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewardcodes_weapons` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `code` VARCHAR(50) NOT NULL,
            `weapon` VARCHAR(50) NOT NULL,
            `quantity` INT(11) NOT NULL DEFAULT 1,
            PRIMARY KEY (`id`),
            KEY `bcc_rc_weapons_code_fk` (`code`),
            CONSTRAINT `bcc_rc_weapons_code_fk` FOREIGN KEY (`code`) REFERENCES `bcc_rewardcodes` (`code`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewards_battlepass_players` (
            `identifier` VARCHAR(120) NOT NULL,
            `charid` INT NOT NULL,
            `season` VARCHAR(60) NOT NULL,
            `xp` INT NOT NULL DEFAULT 0,
            `premium` TINYINT(1) NOT NULL DEFAULT 0,
            `post_rewards` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`, `charid`, `season`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewards_battlepass_claims` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(120) NOT NULL,
            `charid` INT NOT NULL,
            `season` VARCHAR(60) NOT NULL,
            `level` INT NOT NULL,
            `claim_type` VARCHAR(20) NOT NULL,
            `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_battlepass_claim` (`identifier`, `charid`, `season`, `level`, `claim_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewards_battlepass_purchases` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(120) NOT NULL,
            `charid` INT NOT NULL,
            `season` VARCHAR(60) NOT NULL,
            `player_name` VARCHAR(120) DEFAULT NULL,
            `character_name` VARCHAR(160) DEFAULT NULL,
            `price` INT NOT NULL DEFAULT 0,
            `balance_before` INT NOT NULL DEFAULT 0,
            `balance_after` INT NOT NULL DEFAULT 0,
            `purchase_type` VARCHAR(30) NOT NULL DEFAULT 'tokens',
            `purchased_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_identifier_season` (`identifier`, `season`),
            KEY `idx_charid_season` (`charid`, `season`),
            KEY `idx_purchased_at` (`purchased_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_rewards_battlepass_objectives` (
            `identifier` VARCHAR(120) NOT NULL,
            `charid` INT NOT NULL,
            `season` VARCHAR(60) NOT NULL,
            `objective` VARCHAR(80) NOT NULL,
            `period_key` VARCHAR(40) NOT NULL,
            `progress` INT NOT NULL DEFAULT 0,
            `completions` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`, `charid`, `season`, `objective`, `period_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_vip_purchases` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `transaction_id` VARCHAR(100) DEFAULT NULL,
            `package_id` VARCHAR(100) NOT NULL,
            `package_label` VARCHAR(100) NOT NULL,
            `tebex_target` VARCHAR(120) DEFAULT NULL,
            `tebex_username` VARCHAR(120) DEFAULT NULL,
            `tebex_server` VARCHAR(120) DEFAULT NULL,
            `payment_price` VARCHAR(40) DEFAULT NULL,
            `payment_currency` VARCHAR(20) DEFAULT NULL,
            `payment_time` VARCHAR(40) DEFAULT NULL,
            `payment_date` VARCHAR(40) DEFAULT NULL,
            `customer_email` VARCHAR(160) DEFAULT NULL,
            `customer_ip` VARCHAR(80) DEFAULT NULL,
            `package_price` VARCHAR(40) DEFAULT NULL,
            `package_expiry` VARCHAR(80) DEFAULT NULL,
            `package_name` VARCHAR(160) DEFAULT NULL,
            `target_source` INT DEFAULT NULL,
            `target_identifier` VARCHAR(120) NOT NULL,
            `target_charid` INT DEFAULT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `reward_summary` TEXT DEFAULT NULL,
            `failure_reason` TEXT DEFAULT NULL,
            `raw_variables` TEXT DEFAULT NULL,
            `claimed_at` TIMESTAMP NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_transaction_package` (`transaction_id`, `package_id`, `target_identifier`),
            KEY `idx_identifier_status` (`target_identifier`, `status`),
            KEY `idx_charid_status` (`target_charid`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_vip_tokens` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(120) NOT NULL,
            `charid` INT DEFAULT NULL,
            `balance` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_identifier_charid` (`identifier`, `charid`),
            KEY `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_vip_delivery_logs` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `purchase_id` INT DEFAULT NULL,
            `transaction_id` VARCHAR(100) DEFAULT NULL,
            `package_id` VARCHAR(100) DEFAULT NULL,
            `package_label` VARCHAR(100) DEFAULT NULL,
            `target_identifier` VARCHAR(120) DEFAULT NULL,
            `target_charid` INT DEFAULT NULL,
            `target_source` INT DEFAULT NULL,
            `player_name` VARCHAR(120) DEFAULT NULL,
            `tokens_added` INT NOT NULL DEFAULT 0,
            `rol_added` INT NOT NULL DEFAULT 0,
            `delivery_type` VARCHAR(30) NOT NULL DEFAULT 'claim',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_purchase_id` (`purchase_id`),
            KEY `idx_target_identifier` (`target_identifier`),
            KEY `idx_target_charid` (`target_charid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    print('[bcc-rewards] database tables created or updated successfully.')
end)
