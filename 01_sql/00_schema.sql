-- MySQL 8.0+ schema for the committed Golden Dataset
CREATE DATABASE IF NOT EXISTS collections_recovery;
USE collections_recovery;

CREATE TABLE IF NOT EXISTS dim_account (
    account_id VARCHAR(64) PRIMARY KEY,
    borrower_id VARCHAR(64),
    loan_type VARCHAR(64),
    principal_amount DECIMAL(18,2),
    outstanding_amount DECIMAL(18,2),
    dpd INT,
    risk_segment VARCHAR(64),
    status VARCHAR(32),
    opened_at DATETIME,
    timezone VARCHAR(64),
    schema_version VARCHAR(32)
);

CREATE TABLE IF NOT EXISTS dim_agent (
    agent_id VARCHAR(64) PRIMARY KEY,
    employee_code VARCHAR(128),
    vendor_id VARCHAR(64),
    team VARCHAR(128),
    status VARCHAR(32),
    first_seen_active_at DATETIME,
    identity_confidence VARCHAR(128)
);

CREATE TABLE IF NOT EXISTS dim_borrower (
    borrower_id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255),
    phone VARCHAR(64),
    email VARCHAR(255),
    city VARCHAR(128),
    created_at DATETIME,
    updated_at DATETIME,
    state VARCHAR(128),
    identity_confidence VARCHAR(128)
);

CREATE TABLE IF NOT EXISTS dim_campaign (
    campaign_id VARCHAR(64) PRIMARY KEY,
    campaign_family VARCHAR(128),
    channel VARCHAR(64),
    strategy_version VARCHAR(128),
    start_at DATETIME,
    target_definition TEXT,
    end_at DATETIME
);

CREATE TABLE IF NOT EXISTS dim_monthly_working_population (
    month DATE PRIMARY KEY,
    working_population INT
);

CREATE TABLE IF NOT EXISTS fact_account_status_history (
    history_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    status VARCHAR(32),
    changed_by VARCHAR(128),
    source VARCHAR(128),
    recorded_at DATETIME,
    timestamp_integrity_flag VARCHAR(64),
    INDEX idx_status_account_event (account_id, event_at)
);

CREATE TABLE IF NOT EXISTS fact_agent_sessions_golden (
    session_id VARCHAR(64) PRIMARY KEY,
    agent_id VARCHAR(64),
    login_at DATETIME,
    channel VARCHAR(64),
    device_id VARCHAR(128),
    timezone VARCHAR(64),
    logout_at DATETIME,
    INDEX idx_session_agent_login (agent_id, login_at)
);

CREATE TABLE IF NOT EXISTS fact_calls_golden (
    call_id VARCHAR(64),
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    agent_id VARCHAR(64),
    campaign_id VARCHAR(64),
    direction VARCHAR(32),
    vendor_id VARCHAR(64),
    call_status VARCHAR(64),
    duration_sec INT,
    timezone VARCHAR(64),
    event_at_utc DATETIME,
    INDEX idx_calls_account_event (account_id, event_at),
    INDEX idx_calls_campaign (campaign_id)
);

CREATE TABLE IF NOT EXISTS fact_daily_targeting_golden (
    target_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    campaign_id VARCHAR(64),
    target_date DATE,
    priority DECIMAL(18,6),
    recommended_channel VARCHAR(64),
    status VARCHAR(64),
    INDEX idx_target_date (target_date),
    INDEX idx_target_account (account_id)
);

CREATE TABLE IF NOT EXISTS fact_dispositions (
    disposition_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    call_id VARCHAR(64),
    agent_id VARCHAR(64),
    disposition_code VARCHAR(128),
    disposition_version VARCHAR(64),
    disposition_canonical VARCHAR(128),
    INDEX idx_disp_account_event (account_id, event_at)
);

CREATE TABLE IF NOT EXISTS fact_field_visits_golden (
    visit_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    agent_id VARCHAR(64),
    visit_type VARCHAR(64),
    outcome VARCHAR(128),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    scheduled_at DATETIME,
    INDEX idx_visit_account_event (account_id, event_at)
);

CREATE TABLE IF NOT EXISTS fact_payments_golden (
    payment_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    payment_reference VARCHAR(128),
    amount DECIMAL(18,2),
    payment_status VARCHAR(32),
    payment_method VARCHAR(64),
    provider_id VARCHAR(64),
    INDEX idx_payment_account_event (account_id, event_at),
    INDEX idx_payment_reference (payment_reference)
);

CREATE TABLE IF NOT EXISTS fact_promises_to_pay_golden (
    ptp_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    agent_id VARCHAR(64),
    promised_amount DECIMAL(18,2),
    promised_date DATE,
    status VARCHAR(32),
    source VARCHAR(128),
    INDEX idx_ptp_account_date (account_id, promised_date)
);

CREATE TABLE IF NOT EXISTS fact_sms_golden (
    sms_event_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    message_id VARCHAR(128),
    event_type VARCHAR(64),
    template_code VARCHAR(128),
    provider_id VARCHAR(64),
    INDEX idx_sms_account_event (account_id, event_at)
);

CREATE TABLE IF NOT EXISTS fact_whatsapp_golden (
    whatsapp_event_id VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(64),
    borrower_id VARCHAR(64),
    event_at DATETIME,
    message_id VARCHAR(128),
    event_type VARCHAR(64),
    template_code VARCHAR(128),
    provider_id VARCHAR(64),
    INDEX idx_wa_account_event (account_id, event_at)
);
