DROP PACKAGE BODY APPS.XXINTG_INV_ITEM_TEMP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_INV_ITEM_TEMP_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 03-Aug-2013
 File Name     : XXINVITEMTEMPDET.pkb
 Description   : This script creates the package body of
                 XXINTG_INV_ITEM_TEMP_PKG, which will produce report
                 output
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 03-Sep-2013 Debjani Roy           Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE generate_report (errbuf    OUT VARCHAR2
                             ,retcode   OUT NUMBER
                             ,p_inv_org IN  NUMBER
                              )
   IS
      l_concat_output                            VARCHAR2(3000); /*Variable to print concatenated output*/
      l_concat_headers                           CLOB; /*Variable to print concatenated headers. Clob since its more than 4000 char*/
      l_report_title                             VARCHAR2(100) := 'Item Template Detail Report'; /*Variable to store and print report title*/
      l_return_success                           NUMBER        := 0; /*Return code for report success*/
      l_return_failure                           NUMBER        := 2; /*Return code for report failure*/
      l_return_warning                           NUMBER        := 1; /*Return code for report warning*/
      l_errmsg                                   VARCHAR2(500);  /*Variable to hold error message*/
      l_template_exists                          VARCHAR2(1)   := 'N'; /*Base on this variable print whether no data found should be printed or not*/
      /*Following are the variables that will be used as column aliases in PIVOT and select cols for attribute columns*/
      l_item_type                                VARCHAR2(100)    :=  'UI Type';
      l_inventory_item_status_code               VARCHAR2(100)    :=  'Status';
      l_primary_uom_code                         VARCHAR2(100)    :=  'Primary UOM';
      l_allowed_units_lookup_code                VARCHAR2(100)    :=  'Conversions';
      l_description                              VARCHAR2(100)    :=  'Desc';
      l_global_desc_flex                         VARCHAR2(100)    :=  'GDF';
      l_tracking_quantity_ind                    VARCHAR2(100)    :=  'T UOM';
      l_ont_pricing_qty_source                   VARCHAR2(100)    :=  'P UOM';
      l_secondary_default_ind                    VARCHAR2(100)    :=  'Def Control';
      l_secondary_uom_code                       VARCHAR2(100)    :=  'Sec UOM';
      l_dual_uom_deviation_high                  VARCHAR2(100)    :=  'Dev+';
      l_dual_uom_deviation_low                   VARCHAR2(100)    :=  'Dev-';
      l_inventory_item_flag                      VARCHAR2(100)    :=  'Inventory Item';
      l_stock_enabled_flag                       VARCHAR2(100)    :=  'Stockable';
      l_mtl_tran_enabled_flag                    VARCHAR2(100)    :=  'Transactable';
      l_revision_qty_control_code                VARCHAR2(100)    :=  'Revision Control';
      l_lot_control_code                         VARCHAR2(100)    :=  'Lot Control';
      l_start_auto_lot_number                    VARCHAR2(100)    :=  'Starting Lot Number';
      l_auto_lot_alpha_prefix                    VARCHAR2(100)    :=  'Starting Lot Prefix';
      l_serial_number_control_code               VARCHAR2(100)    :=  'Serial Number Generation';
      l_start_auto_serial_number                 VARCHAR2(100)    :=  'Starting Serial Number';
      l_auto_serial_alpha_prefix                 VARCHAR2(100)    :=  'Starting Serial Prefix';
      l_shelf_life_code                          VARCHAR2(100)    :=  'Lot Expiration';
      l_shelf_life_days                          VARCHAR2(100)    :=  'Shelf Life Days';
      l_restrict_subinventories_code             VARCHAR2(100)    :=  'Restrict Subinventories';
      l_location_control_code                    VARCHAR2(100)    :=  'Locator Control';
      l_restrict_locators_code                   VARCHAR2(100)    :=  'Restrict Locators';
      l_reservable_type                          VARCHAR2(100)    :=  'Reservable';
      l_cycle_count_enabled_flag                 VARCHAR2(100)    :=  'Cycle Count Enabled';
      l_negative_measurement_error               VARCHAR2(100)    :=  'Negative Measurement Error';
      l_positive_measurement_error               VARCHAR2(100)    :=  'Positive Measurement Error';
      l_check_shortages_flag                     VARCHAR2(100)    :=  'Check Material Shortage';
      l_lot_status_enabled                       VARCHAR2(100)    :=  'Lot Status Enabled';
      l_default_lot_status_id                    VARCHAR2(100)    :=  'Default Lot Status';
      l_serial_status_enabled                    VARCHAR2(100)    :=  'Serial Status Enabled';
      l_default_serial_status_id                 VARCHAR2(100)    :=  'Default Serial Status';
      l_lot_split_enabled                        VARCHAR2(100)    :=  'Lot Split Enabled';
      l_lot_merge_enabled                        VARCHAR2(100)    :=  'Lot Merge Enabled';
      l_lot_translate_enabled                    VARCHAR2(100)    :=  'Lot Translate Enabled';
      l_lot_substitution_enabled                 VARCHAR2(100)    :=  'Lot Substitution Enabled';
      l_bulk_picked_flag                         VARCHAR2(100)    :=  'Bulk Picked';
      l_lot_divisible_flag                       VARCHAR2(100)    :=  'Lot Divisible';
      l_grade_control_flag                       VARCHAR2(100)    :=  'Grade Controlled';
      l_default_grade                            VARCHAR2(100)    :=  'Default Grade';
      l_child_lot_flag                           VARCHAR2(100)    :=  'Child Lot Enabled';
      l_parent_child_generation_flag             VARCHAR2(100)    :=  'Child Lot Generation';
      l_child_lot_prefix                         VARCHAR2(100)    :=  'Child Lot Prefix';
      l_child_lot_starting_number                VARCHAR2(100)    :=  'Child Lot Starting Number';
      l_child_lot_validation_flag                VARCHAR2(100)    :=  'Child Lot Format Validation';
      l_retest_interval                          VARCHAR2(100)    :=  'Retest Interval';
      l_expiration_action_interval               VARCHAR2(100)    :=  'Expiration Action Interval';
      l_expiration_action_code                   VARCHAR2(100)    :=  'Expiration Action';
      l_maturity_days                            VARCHAR2(100)    :=  'Maturity Days';
      l_hold_days                                VARCHAR2(100)    :=  'Hold Days';
      l_copy_lot_attribute_flag                  VARCHAR2(100)    :=  'Copy Lot Attributes';
      l_bom_item_type                            VARCHAR2(100)    :=  'Bom Item Type';
      l_bom_enabled_flag                         VARCHAR2(100)    :=  'Bom Allowed';
      l_base_item_id                             VARCHAR2(100)    :=  'Base Model';
      l_effectivity_control                      VARCHAR2(100)    :=  'Effectivity Control';
      l_auto_created_config_flag                 VARCHAR2(100)    :=  'Autocreated Configuration';
      l_config_model_type                        VARCHAR2(100)    :=  'Configurator Model Type';
      l_config_orgs                              VARCHAR2(100)    :=  'Create Configured Item, Bom';
      l_config_match                             VARCHAR2(100)    :=  'Match Configuration';
      l_costing_enabled_flag                     VARCHAR2(100)    :=  'Costing Enabled';
      l_inventory_asset_flag                     VARCHAR2(100)    :=  'Inventory Asset Value';
      l_cost_of_sales_account                    VARCHAR2(100)    :=  'Cost Of Goods Sold Account';
      l_def_include_in_rollup_flag               VARCHAR2(100)    :=  'Include In Rollup';
      l_std_lot_size                             VARCHAR2(100)    :=  'Standard Lot Size';
      l_eam_item_type                            VARCHAR2(100)    :=  'EAM Item Type';
      l_eam_activity_type_code                   VARCHAR2(100)    :=  'EAM Activity Type';
      l_eam_activity_cause_code                  VARCHAR2(100)    :=  'EAM Activity Cause';
      l_eam_activity_source_code                 VARCHAR2(100)    :=  'EAM Activity Source';
      l_eam_act_shutdown_status                  VARCHAR2(100)    :=  'EAM Shutdown Type';
      l_eam_act_notification_flag                VARCHAR2(100)    :=  'EAM Notification Required';
      l_purchasing_item_flag                     VARCHAR2(100)    :=  'Purchased';
      l_purchasing_enabled_flag                  VARCHAR2(100)    :=  'Purchasable';
      l_buyer_id                                 VARCHAR2(100)    :=  'Default Buyer';
      l_must_use_app_vendor_flag                 VARCHAR2(100)    :=  'Use Approved Supplier';
      l_purchasing_tax_code                      VARCHAR2(100)    :=  'Input Tax Classification Code';
      l_taxable_flag                             VARCHAR2(100)    :=  'Taxable';
      l_receive_close_tolerance                  VARCHAR2(100)    :=  'Receipt Close Tolerance';
      l_allow_item_desc_update_flag              VARCHAR2(100)    :=  'Allow Description Update';
      l_inspection_required_flag                 VARCHAR2(100)    :=  'Inspection Required';
      l_receipt_required_flag                    VARCHAR2(100)    :=  'Receipt Required';
      l_market_price                             VARCHAR2(100)    :=  'Market Price';
      l_un_number_id                             VARCHAR2(100)    :=  'Un Number';
      l_hazard_class_id                          VARCHAR2(100)    :=  'Hazard Class';
      l_rfq_required_flag                        VARCHAR2(100)    :=  'Rfq Required';
      l_list_price_per_unit                      VARCHAR2(100)    :=  'List Price';
      l_price_tolerance_percent                  VARCHAR2(100)    :=  'Price Tolerance %';
      l_asset_category_id                        VARCHAR2(100)    :=  'Asset Category';
      l_rounding_factor                          VARCHAR2(100)    :=  'Rounding Factor';
      l_unit_of_issue                            VARCHAR2(100)    :=  'Unit Of Issue';
      l_outside_operation_flag                   VARCHAR2(100)    :=  'Outside Processing Item';
      l_outside_operation_uom_type               VARCHAR2(100)    :=  'Outside Processing Unit Type';
      l_invoice_close_tolerance                  VARCHAR2(100)    :=  'Invoice Close Tolerance';
      l_encumbrance_account                      VARCHAR2(100)    :=  'Encumbrance Account';
      l_expense_account                          VARCHAR2(100)    :=  'Expense Account';
      l_outsourced_assembly                      VARCHAR2(100)    :=  'Outsourced Assembly';
      l_qty_rcv_exception_code                   VARCHAR2(100)    :=  'Over-Receipt Qty Action';
      l_receiving_routing_id                     VARCHAR2(100)    :=  'Receipt Routing';
      l_qty_rcv_tolerance                        VARCHAR2(100)    :=  'Over-Receipt Qty Tolerance';
      l_enforce_ship_to_loc_code                 VARCHAR2(100)    :=  'Enforce Ship-To';
      l_allow_substitute_rec_flag                VARCHAR2(100)    :=  'Allow Substitute Receipts';
      l_allow_unordered_rec_flag                 VARCHAR2(100)    :=  'Allow Unordered Receipts';
      l_allow_express_delivery_flag              VARCHAR2(100)    :=  'Allow Express Transactions';
      l_days_early_receipt_allowed               VARCHAR2(100)    :=  'Days Early Receipt Allowed';
      l_days_late_receipt_allowed                VARCHAR2(100)    :=  'Days Late Receipt Allowed';
      l_receipt_days_exception_code              VARCHAR2(100)    :=  'Receipt Date Action';
      l_weight_uom_code                          VARCHAR2(100)    :=  'Weight Unit Of Measure';
      l_unit_weight                              VARCHAR2(100)    :=  'Unit Weight';
      l_volume_uom_code                          VARCHAR2(100)    :=  'Volume Unit Of Measure';
      l_unit_volume                              VARCHAR2(100)    :=  'Unit Volume';
      l_container_item_flag                      VARCHAR2(100)    :=  'Container';
      l_vehicle_item_flag                        VARCHAR2(100)    :=  'Vehicle';
      l_maximum_load_weight                      VARCHAR2(100)    :=  'Maximum Load Weight';
      l_minimum_fill_percent                     VARCHAR2(100)    :=  'Minimum Fill Percentage';
      l_internal_volume                          VARCHAR2(100)    :=  'Internal Volume';
      l_container_type_code                      VARCHAR2(100)    :=  'Container Type';
      l_collateral_flag                          VARCHAR2(100)    :=  'Collateral Item';
      l_equipment_type                           VARCHAR2(100)    :=  'Equipment';
      l_indivisible_flag                         VARCHAR2(100)    :=  'Om Indivisible';
      l_dimension_uom_code                       VARCHAR2(100)    :=  'Dimension Unit Of Measure';
      l_unit_length                              VARCHAR2(100)    :=  'Length';
      l_unit_width                               VARCHAR2(100)    :=  'Width';
      l_unit_height                              VARCHAR2(100)    :=  'Height';
      l_inventory_planning_code                  VARCHAR2(100)    :=  'Inventory Planning Method';
      l_planner_code                             VARCHAR2(100)    :=  'Planner';
      l_planning_make_buy_code                   VARCHAR2(100)    :=  'Make Or Buy';
      l_min_minmax_quantity                      VARCHAR2(100)    :=  'Min-Max Minimum Quantity';
      l_max_minmax_quantity                      VARCHAR2(100)    :=  'Min-Max Maximum Quantity';
      l_safety_stock_bucket_days                 VARCHAR2(100)    :=  'Safety Stock Bucket Days';
      l_carrying_cost                            VARCHAR2(100)    :=  'Carrying Cost Percent';
      l_order_cost                               VARCHAR2(100)    :=  'Order Cost';
      l_mrp_safety_stock_percent                 VARCHAR2(100)    :=  'Safety Stock Percent';
      l_mrp_safety_stock_code                    VARCHAR2(100)    :=  'Safety Stock';
      l_fixed_order_quantity                     VARCHAR2(100)    :=  'Fixed Order Quantity';
      l_fixed_days_supply                        VARCHAR2(100)    :=  'Fixed Days Supply';
      l_minimum_order_quantity                   VARCHAR2(100)    :=  'Minimum Order Quantity';
      l_maximum_order_quantity                   VARCHAR2(100)    :=  'Maximum Order Quantity';
      l_fixed_lot_multiplier                     VARCHAR2(100)    :=  'Fixed Lot Size Multiplier';
      l_source_type                              VARCHAR2(100)    :=  'Source Type';
      l_source_organization_id                   VARCHAR2(100)    :=  'Source Organization';
      l_source_subinventory                      VARCHAR2(100)    :=  'Source Subinventory';
      l_vmi_minimum_units                        VARCHAR2(100)    :=  'Minimum Quantity';
      l_vmi_minimum_days                         VARCHAR2(100)    :=  'Minimum Days Of Supply';
      l_vmi_maximum_units                        VARCHAR2(100)    :=  'Maximum Quantity';
      l_vmi_maximum_days                         VARCHAR2(100)    :=  'Maximum Days Of Supply';
      l_vmi_fixed_order_quantity                 VARCHAR2(100)    :=  'Fixed Quantity';
      l_so_authorization_flag                    VARCHAR2(100)    :=  'Release Authorization Required';
      l_consigned_flag                           VARCHAR2(100)    :=  'Consigned';
      l_vmi_forecast_type                        VARCHAR2(100)    :=  'Forecast Type';
      l_forecast_horizon                         VARCHAR2(100)    :=  'Window Days';
      l_asn_autoexpire_flag                      VARCHAR2(100)    :=  'Auto-Expire Asn';
      l_subcontracting_component                 VARCHAR2(100)    :=  'Subcontracting Component';
      l_mrp_planning_code                        VARCHAR2(100)    :=  'Mrp Planning Method';
      l_ato_forecast_control                     VARCHAR2(100)    :=  'Forecast Control';
      l_planning_exception_set                   VARCHAR2(100)    :=  'Planning Exception Set';
      l_shrinkage_rate                           VARCHAR2(100)    :=  'Shrinkage Rate';
      l_end_assembly_pegging_flag                VARCHAR2(100)    :=  'End Assembly Pegging';
      l_rounding_control_type                    VARCHAR2(100)    :=  'Round Order Quantities';
      l_planned_inv_point_flag                   VARCHAR2(100)    :=  'Planned Inventory Point';
      l_create_supply_flag                       VARCHAR2(100)    :=  'Create Supply';
      l_acceptable_early_days                    VARCHAR2(100)    :=  'Acceptable Early Days';
      l_critical_component_flag                  VARCHAR2(100)    :=  'Critical Component';
      l_exclude_from_budget_flag                 VARCHAR2(100)    :=  'Exclude From Budget';
      l_mrp_calculate_atp_flag                   VARCHAR2(100)    :=  'Calculate Atp';
      l_auto_reduce_mps                          VARCHAR2(100)    :=  'Reduce Mps';
      l_repetitive_planning_flag                 VARCHAR2(100)    :=  'Repetitive Planning';
      l_overrun_percentage                       VARCHAR2(100)    :=  'Overrun Percentage';
      l_acceptable_rate_decrease                 VARCHAR2(100)    :=  'Acceptable Rate -';
      l_acceptable_rate_increase                 VARCHAR2(100)    :=  'Acceptable Rate +';
      l_planning_time_fence_code                 VARCHAR2(100)    :=  'Planning Time Fence';
      l_planning_time_fence_days                 VARCHAR2(100)    :=  'Planning Time Fence Days';
      l_demand_time_fence_code                   VARCHAR2(100)    :=  'Demand Time Fence';
      l_demand_time_fence_days                   VARCHAR2(100)    :=  'Demand Time Fence Days';
      l_release_time_fence_code                  VARCHAR2(100)    :=  'Release Time Fence';
      l_release_time_fence_days                  VARCHAR2(100)    :=  'Release Time Fence Days';
      l_substitution_window_code                 VARCHAR2(100)    :=  'Substitution Window';
      l_substitution_window_days                 VARCHAR2(100)    :=  'Substitution Window Days';
      l_drp_planned_flag                         VARCHAR2(100)    :=  'Drp Planned';
      l_days_max_inv_supply                      VARCHAR2(100)    :=  'Maximum Inventory Days Supply';
      l_days_max_inv_window                      VARCHAR2(100)    :=  'Maximum Inventory Window';
      l_days_tgt_inv_supply                      VARCHAR2(100)    :=  'Target Inventory Days Supply';
      l_days_tgt_inv_window                      VARCHAR2(100)    :=  'Target Inventory Window';
      l_continous_transfer                       VARCHAR2(100)    :=  'Continuous Inter Org Transfers';
      l_convergence                              VARCHAR2(100)    :=  'Convergence Pattern';
      l_divergence                               VARCHAR2(100)    :=  'Divergence Pattern';
      l_repair_program                           VARCHAR2(100)    :=  'Repair Program';
      l_repair_leadtime                          VARCHAR2(100)    :=  'Repair Lead-Time';
      l_repair_yield                             VARCHAR2(100)    :=  'Repair Yield';
      l_preposition_point                        VARCHAR2(100)    :=  'Pre-Positioning Point';
      l_preprocessing_lead_time                  VARCHAR2(100)    :=  'Preprocessing Lead Time';
      l_full_lead_time                           VARCHAR2(100)    :=  'Processing Lead Time';
      l_postprocessing_lead_time                 VARCHAR2(100)    :=  'Postprocessing Lead Time';
      l_fixed_lead_time                          VARCHAR2(100)    :=  'Fixed Lead Time';
      l_variable_lead_time                       VARCHAR2(100)    :=  'Variable Lead Time';
      l_cum_manufacturing_lead_time              VARCHAR2(100)    :=  'Cum Manufacturing Lead Time';
      l_cumulative_total_lead_time               VARCHAR2(100)    :=  'Cumulative Total Lead Time';
      l_lead_time_lot_size                       VARCHAR2(100)    :=  'Lead Time Lot Size';
      l_build_in_wip_flag                        VARCHAR2(100)    :=  'Build In Wip';
      l_wip_supply_type                          VARCHAR2(100)    :=  'Wip Supply Type';
      l_wip_supply_subinventory                  VARCHAR2(100)    :=  'Wip Supply Subinventory';
      l_wip_supply_locator_id                    VARCHAR2(100)    :=  'Wip Supply Locator';
      l_overcompletion_tol_type                  VARCHAR2(100)    :=  'Overcompletion Tolerance Type';
      l_overcompletion_tol_value                 VARCHAR2(100)    :=  'Overcompletion Tolerance Value';
      l_inventory_carry_penalty                  VARCHAR2(100)    :=  'Inventory Carry Penalty';
      l_operation_slack_penalty                  VARCHAR2(100)    :=  'Operation Slack Penalty';
      l_customer_order_flag                      VARCHAR2(100)    :=  'Customer Ordered';
      l_customer_order_enabled_flag              VARCHAR2(100)    :=  'Customer Orders Enabled';
      l_internal_order_flag                      VARCHAR2(100)    :=  'Internal Ordered';
      l_internal_order_enabled_flag              VARCHAR2(100)    :=  'Internal Orders Enabled';
      l_shippable_item_flag                      VARCHAR2(100)    :=  'Shippable';
      l_so_transactions_flag                     VARCHAR2(100)    :=  'Oe Transactable';
      l_picking_rule_id                          VARCHAR2(100)    :=  'Picking Rule';
      l_pick_components_flag                     VARCHAR2(100)    :=  'Pick Components';
      l_replenish_to_order_flag                  VARCHAR2(100)    :=  'Assemble To Order';
      l_atp_flag                                 VARCHAR2(100)    :=  'Check Atp';
      l_atp_components_flag                      VARCHAR2(100)    :=  'Atp Components';
      l_atp_rule_id                              VARCHAR2(100)    :=  'Atp Rule';
      l_ship_model_complete_flag                 VARCHAR2(100)    :=  'Ship Model Complete';
      l_default_shipping_org                     VARCHAR2(100)    :=  'Default Shipping Organization';
      l_default_so_source_type                   VARCHAR2(100)    :=  'Default So Source Type';
      l_returnable_flag                          VARCHAR2(100)    :=  'Returnable';
      l_return_inspection_req                    VARCHAR2(100)    :=  'Rma Inspection Required';
      l_over_shipment_tolerance                  VARCHAR2(100)    :=  'Over Shipment Tolerance';
      l_under_shipment_tolerance                 VARCHAR2(100)    :=  'Under Shipment Tolerance';
      l_over_return_tolerance                    VARCHAR2(100)    :=  'Over Return Tolerance';
      l_under_return_tolerance                   VARCHAR2(100)    :=  'Under Return Tolerance';
      l_financing_allowed_flag                   VARCHAR2(100)    :=  'Financing Allowed';
      l_charge_periodicity_code                  VARCHAR2(100)    :=  'Charge Periodicity';
      l_invoiceable_item_flag                    VARCHAR2(100)    :=  'Invoiceable Item';
      l_invoice_enabled_flag                     VARCHAR2(100)    :=  'Invoice Enabled';
      l_accounting_rule_id                       VARCHAR2(100)    :=  'Accounting Rule';
      l_invoicing_rule_id                        VARCHAR2(100)    :=  'Invoicing Rule';
      l_tax_code                                 VARCHAR2(100)    :=  'Output Tax Classification Code';
      l_sales_account                            VARCHAR2(100)    :=  'Sales Account';
      l_payment_terms_id                         VARCHAR2(100)    :=  'Payment Terms';
      l_contract_item_type_code                  VARCHAR2(100)    :=  'Contract Item Type';
      l_service_duration_period_code             VARCHAR2(100)    :=  'Contract Duration Period';
      l_service_duration                         VARCHAR2(100)    :=  'Contract Duration';
      l_coverage_schedule_id                     VARCHAR2(100)    :=  'Coverage Template';
      l_serv_req_enabled_code                    VARCHAR2(100)    :=  'Service Request';
      l_serviceable_product_flag                 VARCHAR2(100)    :=  'Enable Contract Coverage';
      l_material_billable_flag                   VARCHAR2(100)    :=  'Billing Type';
      l_serv_billing_enabled_flag                VARCHAR2(100)    :=  'Enable Service Billing';
      l_defect_tracking_on_flag                  VARCHAR2(100)    :=  'Enable Defect Tracking';
      l_comms_nl_trackable_flag                  VARCHAR2(100)    :=  'Track In Installed Base';
      l_asset_creation_code                      VARCHAR2(100)    :=  'Create Fixed Asset';
      l_ib_item_instance_class                   VARCHAR2(100)    :=  'Item Instance Class';
      l_service_starting_delay                   VARCHAR2(100)    :=  'Starting Delay (Days)';
      l_web_status                               VARCHAR2(100)    :=  'Web Status';
      l_orderable_on_web_flag                    VARCHAR2(100)    :=  'Orderable On The Web';
      l_back_orderable_flag                      VARCHAR2(100)    :=  'Back Orderable';
      l_minimum_license_quantity                 VARCHAR2(100)    :=  'Minimum License Quantity';
      l_recipe_enabled_flag                      VARCHAR2(100)    :=  'Recipe Enabled';
      l_process_quality_enabled_flag             VARCHAR2(100)    :=  'Process Quality Enabled';
      l_process_exec_enabled_flag                VARCHAR2(100)    :=  'Process Execution Enabled';
      l_process_costing_enabled_flag             VARCHAR2(100)    :=  'Process Costing Enabled';
      l_process_supply_subinventory              VARCHAR2(100)    :=  'Process Supply Subinventory';
      l_process_supply_locator_id                VARCHAR2(100)    :=  'Process Supply Locator';
      l_process_yield_subinventory               VARCHAR2(100)    :=  'Process Yield Subinventory';
      l_process_yield_locator_id                 VARCHAR2(100)    :=  'Process Yield Locator';
      l_hazardous_material_flag                  VARCHAR2(100)    :=  'Hazardous Material';
      l_cas_number                               VARCHAR2(100)    :=  'Cas Number';
      l_serviceable_component_flag               VARCHAR2(100)    :=  'Serviceable Component Flag' ;
      l_descriptive_flexfield                    VARCHAR2(100)    :=  'Descriptive Flexfield'      ;
      l_max_warranty_amount                      VARCHAR2(100)    :=  'Max Warranty Amount'        ;
      l_prorate_service_flag                     VARCHAR2(100)    :=  'Prorate Service Flag'       ;
      l_base_warranty_service_id                 VARCHAR2(100)    :=  'Base Warranty Service Id'   ;
      l_engineering_date                         VARCHAR2(100)    :=  'Engineering Date'           ;
      l_new_revision_code                        VARCHAR2(100)    :=  'New Revision Code'          ;
      l_response_time_value                      VARCHAR2(100)    :=  'Response Time Value'        ;
      l_vol_discount_exempt_flag                 VARCHAR2(100)    :=  'Vol Discount Exempt Flag'   ;
      l_serv_importance_level                    VARCHAR2(100)    :=  'Serv Importance Level'      ;
      l_response_time_period_code                VARCHAR2(100)    :=  'Response Time Period Code'  ;
      l_vendor_warranty_flag                     VARCHAR2(100)    :=  'Vendor Warranty Flag'       ;
      l_serviceable_item_class_id                VARCHAR2(100)    :=  'Serviceable Item Class Id'  ;
      l_event                                    VARCHAR2(100)    :=  'Event'                      ;
      l_coupon_exempt_flag                       VARCHAR2(100)    :=  'Coupon Exempt Flag'         ;
      l_subscription_depend_flag                 VARCHAR2(100)    :=  'Subscription Depend Flag'   ;
      l_serial_tagging_flag                      VARCHAR2(100)    :=  'Serial Tagging Flag'        ;
      l_preventive_maintenance_flag              VARCHAR2(100)    :=  'Preventive Maintenance Flag';
      l_warranty_vendor_id                       VARCHAR2(100)    :=  'Warranty Vendor Id'         ;
      l_primary_specialist_id                    VARCHAR2(100)    :=  'Primary Specialist Id'      ;
      l_usage_item_flag                          VARCHAR2(100)    :=  'Usage Item Flag'            ;
      l_recovered_part_disposition               VARCHAR2(100)    :=  'Recovered Part Disposition' ;
      l_downloadable                             VARCHAR2(100)    :=  'Downloadable'               ;
      l_service_item_flag                        VARCHAR2(100)    :=  'Service Item Flag'          ;
      l_secondary_specialist_id                  VARCHAR2(100)    :=  'Secondary Specialist Id'    ;
      l_electronic_format                        VARCHAR2(100)    :=  'Electronic Format'          ;
      l_long_description                         VARCHAR2(100)    :=  'Long Description'           ;
      l_dual_uom_control                         VARCHAR2(100)    :=  'Dual UOM Control'           ;
      l_primary_unit_of_measure                  VARCHAR2(100)    :=  'Primary UOM'    ;
      l_enable_provisioning                      VARCHAR2(100)    :=  'Enable Provisioning'        ;
      l_trade_item_descriptor                    VARCHAR2(100)    :=  'Trade Item Descriptor'      ;




      /*Cursor to fetch template details*/
      CURSOR c_distinct_templates
      IS
      SELECT template_id
            ,template_name
            ,description
        FROM mtl_item_templates_all_v mit
       WHERE (context_organization_id = p_inv_org
              OR p_inv_org IS NULL)
      ORDER BY template_name;

   BEGIN
       retcode := l_return_success  ;
       /*Print report title with system date*/
       fnd_file.put_line(fnd_file.output,l_report_title||' as on '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
       SELECT  to_clob(
                     'Name'
              ||'|'||'Description'
                   ||'|'||l_item_type
                   ||'|'||l_inventory_item_status_code
                   ||'|'||l_primary_uom_code
                   ||'|'||l_allowed_units_lookup_code
                   ||'|'||l_description
                   ||'|'||l_global_desc_flex
                   ||'|'||l_tracking_quantity_ind
                   ||'|'||l_ont_pricing_qty_source
                   ||'|'||l_secondary_default_ind
                   ||'|'||l_secondary_uom_code
                   ||'|'||l_dual_uom_deviation_high
                   ||'|'||l_dual_uom_deviation_low
                   ||'|'||l_inventory_item_flag
                   ||'|'||l_stock_enabled_flag
                   ||'|'||l_mtl_tran_enabled_flag
                   ||'|'||l_revision_qty_control_code
                   ||'|'||l_lot_control_code
                   ||'|'||l_start_auto_lot_number
                   ||'|'||l_auto_lot_alpha_prefix
                   ||'|'||l_serial_number_control_code
                   ||'|'||l_start_auto_serial_number
                   ||'|'||l_auto_serial_alpha_prefix
                   ||'|'||l_shelf_life_code
                   ||'|'||l_shelf_life_days
                   ||'|'||l_restrict_subinventories_code
                   ||'|'||l_location_control_code
                   ||'|'||l_restrict_locators_code
                   ||'|'||l_reservable_type
                   ||'|'||l_cycle_count_enabled_flag
                   ||'|'||l_negative_measurement_error
                   ||'|'||l_positive_measurement_error
                   ||'|'||l_check_shortages_flag
                   ||'|'||l_lot_status_enabled
                   ||'|'||l_default_lot_status_id
                   ||'|'||l_serial_status_enabled
                   ||'|'||l_default_serial_status_id
                   ||'|'||l_lot_split_enabled
                   ||'|'||l_lot_merge_enabled
                   ||'|'||l_lot_translate_enabled
                   ||'|'||l_lot_substitution_enabled
                   ||'|'||l_bulk_picked_flag
                   ||'|'||l_lot_divisible_flag
                   ||'|'||l_grade_control_flag
                   ||'|'||l_default_grade
                   ||'|'||l_child_lot_flag
                   ||'|'||l_parent_child_generation_flag
                   ||'|'||l_child_lot_prefix
                   ||'|'||l_child_lot_starting_number
                   ||'|'||l_child_lot_validation_flag
                   ||'|'||l_retest_interval
                   ||'|'||l_expiration_action_interval
                   ||'|'||l_expiration_action_code
                   ||'|'||l_maturity_days
                   ||'|'||l_hold_days
                   ||'|'||l_copy_lot_attribute_flag
                   ||'|'||l_bom_item_type
                   ||'|'||l_bom_enabled_flag
                   ||'|'||l_base_item_id
                   ||'|'||l_effectivity_control
                   ||'|'||l_auto_created_config_flag
                   ||'|'||l_config_model_type
                   ||'|'||l_config_orgs
                   ||'|'||l_config_match
                   ||'|'||l_costing_enabled_flag
                   ||'|'||l_inventory_asset_flag
                   ||'|'||l_cost_of_sales_account
                   ||'|'||l_def_include_in_rollup_flag
                   ||'|'||l_std_lot_size
                   ||'|'||l_eam_item_type
                   ||'|'||l_eam_activity_type_code
                   ||'|'||l_eam_activity_cause_code
                   ||'|'||l_eam_activity_source_code
                   ||'|'||l_eam_act_shutdown_status
                   ||'|'||l_eam_act_notification_flag
                   ||'|'||l_purchasing_item_flag
                   ||'|'||l_purchasing_enabled_flag
                   ||'|'||l_buyer_id
                   ||'|'||l_must_use_app_vendor_flag
                   ||'|'||l_purchasing_tax_code
                   ||'|'||l_taxable_flag
                   ||'|'||l_receive_close_tolerance
                   ||'|'||l_allow_item_desc_update_flag
                   ||'|'||l_inspection_required_flag
                   ||'|'||l_receipt_required_flag
                   ||'|'||l_market_price
                   ||'|'||l_un_number_id
                   ||'|'||l_hazard_class_id
                   ||'|'||l_rfq_required_flag
                   ||'|'||l_list_price_per_unit
                   ||'|'||l_price_tolerance_percent
                   ||'|'||l_asset_category_id
                   ||'|'||l_rounding_factor
                   ||'|'||l_unit_of_issue
                   ||'|'||l_outside_operation_flag
                   ||'|'||l_outside_operation_uom_type
                   ||'|'||l_invoice_close_tolerance
                   ||'|'||l_encumbrance_account
                   ||'|'||l_expense_account
                   ||'|'||l_outsourced_assembly
                   ||'|'||l_qty_rcv_exception_code
                   ||'|'||l_receiving_routing_id
                   ||'|'||l_qty_rcv_tolerance
                   ||'|'||l_enforce_ship_to_loc_code
                   ||'|'||l_allow_substitute_rec_flag
                   ||'|'||l_allow_unordered_rec_flag
                   ||'|'||l_allow_express_delivery_flag
                   ||'|'||l_days_early_receipt_allowed
                   ||'|'||l_days_late_receipt_allowed
                   ||'|'||l_receipt_days_exception_code
                   ||'|'||l_weight_uom_code
                   ||'|'||l_unit_weight
                   ||'|'||l_volume_uom_code
                   ||'|'||l_unit_volume
                   ||'|'||l_container_item_flag
                   ||'|'||l_vehicle_item_flag
                   ||'|'||l_maximum_load_weight
                   ||'|'||l_minimum_fill_percent
                   ||'|'||l_internal_volume
                   ||'|'||l_container_type_code
                   ||'|'||l_collateral_flag
                   ||'|'||l_equipment_type
                   ||'|'||l_indivisible_flag
                   ||'|'||l_dimension_uom_code
                   ||'|'||l_unit_length
                   ||'|'||l_unit_width
                   ||'|'||l_unit_height
                   ||'|'||l_inventory_planning_code
                   ||'|'||l_planner_code
                   ||'|'||l_planning_make_buy_code
                   ||'|'||l_min_minmax_quantity
                   ||'|'||l_max_minmax_quantity
                   ||'|'||l_safety_stock_bucket_days
                   ||'|'||l_carrying_cost
                   ||'|'||l_order_cost
                   ||'|'||l_mrp_safety_stock_percent
                   ||'|'||l_mrp_safety_stock_code
                   ||'|'||l_fixed_order_quantity
                   ||'|'||l_fixed_days_supply
                   ||'|'||l_minimum_order_quantity
                   ||'|'||l_maximum_order_quantity
                   ||'|'||l_fixed_lot_multiplier
                   ||'|'||l_source_type
                   ||'|'||l_source_organization_id
                   ||'|'||l_source_subinventory
                   ||'|'||l_vmi_minimum_units
                   ||'|'||l_vmi_minimum_days
                   ||'|'||l_vmi_maximum_units
                   ||'|'||l_vmi_maximum_days
                   ||'|'||l_vmi_fixed_order_quantity
                   ||'|'||l_so_authorization_flag
                   ||'|'||l_consigned_flag
                   ||'|'||l_vmi_forecast_type
                   ||'|'||l_forecast_horizon
                   ||'|'||l_asn_autoexpire_flag
                   ||'|'||l_subcontracting_component
                   ||'|'||l_mrp_planning_code
                   ||'|'||l_ato_forecast_control
                   ||'|'||l_planning_exception_set
                   ||'|'||l_shrinkage_rate
                   ||'|'||l_end_assembly_pegging_flag
                   ||'|'||l_rounding_control_type
                   ||'|'||l_planned_inv_point_flag
                   ||'|'||l_create_supply_flag
                   ||'|'||l_acceptable_early_days
                   ||'|'||l_critical_component_flag
                   ||'|'||l_exclude_from_budget_flag
                   ||'|'||l_mrp_calculate_atp_flag
                   ||'|'||l_auto_reduce_mps
                   ||'|'||l_repetitive_planning_flag
                   ||'|'||l_overrun_percentage
                   ||'|'||l_acceptable_rate_decrease
                   ||'|'||l_acceptable_rate_increase
                   ||'|'||l_planning_time_fence_code
                   ||'|'||l_planning_time_fence_days
                   ||'|'||l_demand_time_fence_code
                   ||'|'||l_demand_time_fence_days
                    )||'|'||
                   to_clob(l_release_time_fence_code
                   ||'|'||l_release_time_fence_days
                   ||'|'||l_substitution_window_code
                   ||'|'||l_substitution_window_days
                   ||'|'||l_drp_planned_flag
                   ||'|'||l_days_max_inv_supply
                   ||'|'||l_days_max_inv_window
                   ||'|'||l_days_tgt_inv_supply
                   ||'|'||l_days_tgt_inv_window
                   ||'|'||l_continous_transfer
                   ||'|'||l_convergence
                   ||'|'||l_divergence
                   ||'|'||l_repair_program
                   ||'|'||l_repair_leadtime
                   ||'|'||l_repair_yield
                   ||'|'||l_preposition_point
                   ||'|'||l_preprocessing_lead_time
                   ||'|'||l_full_lead_time
                   ||'|'||l_postprocessing_lead_time
                   ||'|'||l_fixed_lead_time
                   ||'|'||l_variable_lead_time
                   ||'|'||l_cum_manufacturing_lead_time
                   ||'|'||l_cumulative_total_lead_time
                   ||'|'||l_lead_time_lot_size
                   ||'|'||l_build_in_wip_flag
                   ||'|'||l_wip_supply_type
                   ||'|'||l_wip_supply_subinventory
                   ||'|'||l_wip_supply_locator_id
                   ||'|'||l_overcompletion_tol_type
                   ||'|'||l_overcompletion_tol_value
                   ||'|'||l_inventory_carry_penalty
                   ||'|'||l_operation_slack_penalty
                   ||'|'||l_customer_order_flag
                   ||'|'||l_customer_order_enabled_flag
                   ||'|'||l_internal_order_flag
                   ||'|'||l_internal_order_enabled_flag
                   ||'|'||l_shippable_item_flag
                   ||'|'||l_so_transactions_flag
                   ||'|'||l_picking_rule_id
                   ||'|'||l_pick_components_flag
                   ||'|'||l_replenish_to_order_flag
                   ||'|'||l_atp_flag
                   ||'|'||l_atp_components_flag
                   ||'|'||l_atp_rule_id
                   ||'|'||l_ship_model_complete_flag
                   ||'|'||l_default_shipping_org
                   ||'|'||l_default_so_source_type
                   ||'|'||l_returnable_flag
                   ||'|'||l_return_inspection_req
                   ||'|'||l_over_shipment_tolerance
                   ||'|'||l_under_shipment_tolerance
                   ||'|'||l_over_return_tolerance
                   ||'|'||l_under_return_tolerance
                   ||'|'||l_financing_allowed_flag
                   ||'|'||l_charge_periodicity_code
                   ||'|'||l_invoiceable_item_flag
                   ||'|'||l_invoice_enabled_flag
                   ||'|'||l_accounting_rule_id
                   ||'|'||l_invoicing_rule_id
                   ||'|'||l_tax_code
                   ||'|'||l_sales_account
                   ||'|'||l_payment_terms_id
                   ||'|'||l_contract_item_type_code
                   ||'|'||l_service_duration_period_code
                   ||'|'||l_service_duration
                   ||'|'||l_coverage_schedule_id
                   ||'|'||l_serv_req_enabled_code
                   ||'|'||l_serviceable_product_flag
                   ||'|'||l_material_billable_flag
                   ||'|'||l_serv_billing_enabled_flag
                   ||'|'||l_defect_tracking_on_flag
                   ||'|'||l_comms_nl_trackable_flag
                   ||'|'||l_asset_creation_code
                   ||'|'||l_ib_item_instance_class
                   ||'|'||l_service_starting_delay
                   ||'|'||l_web_status
                   ||'|'||l_orderable_on_web_flag
                   ||'|'||l_back_orderable_flag
                   ||'|'||l_minimum_license_quantity
                   ||'|'||l_recipe_enabled_flag
                   ||'|'||l_process_quality_enabled_flag
                   ||'|'||l_process_exec_enabled_flag
                   ||'|'||l_process_costing_enabled_flag
                   ||'|'||l_process_supply_subinventory
                   ||'|'||l_process_supply_locator_id
                   ||'|'||l_process_yield_subinventory
                   ||'|'||l_process_yield_locator_id
                   ||'|'||l_hazardous_material_flag
                   ||'|'||l_cas_number
                   ||'|'||l_serviceable_component_flag
                   ||'|'||l_descriptive_flexfield
                   ||'|'||l_max_warranty_amount
                   ||'|'||l_prorate_service_flag
                   ||'|'||l_base_warranty_service_id
                   ||'|'||l_engineering_date
                   ||'|'||l_new_revision_code
                   ||'|'||l_response_time_value
                   ||'|'||l_vol_discount_exempt_flag
                   ||'|'||l_serv_importance_level
                   ||'|'||l_response_time_period_code
                   ||'|'||l_vendor_warranty_flag
                   ||'|'||l_serviceable_item_class_id
                   ||'|'||l_event
                   ||'|'||l_coupon_exempt_flag
                   ||'|'||l_subscription_depend_flag
                   ||'|'||l_serial_tagging_flag
                   ||'|'||l_preventive_maintenance_flag
                   ||'|'||l_warranty_vendor_id
                   ||'|'||l_primary_specialist_id
                   ||'|'||l_usage_item_flag
                   ||'|'||l_recovered_part_disposition
                   ||'|'||l_downloadable
                   ||'|'||l_service_item_flag
                   ||'|'||l_secondary_specialist_id
                   ||'|'||l_electronic_format
                   ||'|'||l_long_description
                   ||'|'||l_dual_uom_control
                   ||'|'||l_primary_unit_of_measure
                   ||'|'||l_enable_provisioning
                   ||'|'||l_trade_item_descriptor

                   )
              INTO l_concat_headers
              FROM DUAL;
              /*Print report headers*/
              fnd_file.put_line(fnd_file.output,l_concat_headers);

       FOR distinct_templates_rec IN c_distinct_templates LOOP
          /*Print template abd attribute details one at a time*/
          l_template_exists := 'Y';
          BEGIN
             SELECT template_name
                   ||'|'||description
                   ||'|'||l_item_type
                   ||'|'||l_inventory_item_status_code
                   ||'|'||l_primary_uom_code
                   ||'|'||l_allowed_units_lookup_code
                   ||'|'||l_description
                   ||'|'||l_global_desc_flex
                   ||'|'||l_tracking_quantity_ind
                   ||'|'||l_ont_pricing_qty_source
                   ||'|'||l_secondary_default_ind
                   ||'|'||l_secondary_uom_code
                   ||'|'||l_dual_uom_deviation_high
                   ||'|'||l_dual_uom_deviation_low
                   ||'|'||l_inventory_item_flag
                   ||'|'||l_stock_enabled_flag
                   ||'|'||l_mtl_tran_enabled_flag
                   ||'|'||l_revision_qty_control_code
                   ||'|'||l_lot_control_code
                   ||'|'||l_start_auto_lot_number
                   ||'|'||l_auto_lot_alpha_prefix
                   ||'|'||l_serial_number_control_code
                   ||'|'||l_start_auto_serial_number
                   ||'|'||l_auto_serial_alpha_prefix
                   ||'|'||l_shelf_life_code
                   ||'|'||l_shelf_life_days
                   ||'|'||l_restrict_subinventories_code
                   ||'|'||l_location_control_code
                   ||'|'||l_restrict_locators_code
                   ||'|'||l_reservable_type
                   ||'|'||l_cycle_count_enabled_flag
                   ||'|'||l_negative_measurement_error
                   ||'|'||l_positive_measurement_error
                   ||'|'||l_check_shortages_flag
                   ||'|'||l_lot_status_enabled
                   ||'|'||l_default_lot_status_id
                   ||'|'||l_serial_status_enabled
                   ||'|'||l_default_serial_status_id
                   ||'|'||l_lot_split_enabled
                   ||'|'||l_lot_merge_enabled
                   ||'|'||l_lot_translate_enabled
                   ||'|'||l_lot_substitution_enabled
                   ||'|'||l_bulk_picked_flag
                   ||'|'||l_lot_divisible_flag
                   ||'|'||l_grade_control_flag
                   ||'|'||l_default_grade
                   ||'|'||l_child_lot_flag
                   ||'|'||l_parent_child_generation_flag
                   ||'|'||l_child_lot_prefix
                   ||'|'||l_child_lot_starting_number
                   ||'|'||l_child_lot_validation_flag
                   ||'|'||l_retest_interval
                   ||'|'||l_expiration_action_interval
                   ||'|'||l_expiration_action_code
                   ||'|'||l_maturity_days
                   ||'|'||l_hold_days
                   ||'|'||l_copy_lot_attribute_flag
                   ||'|'||l_bom_item_type
                   ||'|'||l_bom_enabled_flag
                   ||'|'||l_base_item_id
                   ||'|'||l_effectivity_control
                   ||'|'||l_auto_created_config_flag
                   ||'|'||l_config_model_type
                   ||'|'||l_config_orgs
                   ||'|'||l_config_match
                   ||'|'||l_costing_enabled_flag
                   ||'|'||l_inventory_asset_flag
                   ||'|'||l_cost_of_sales_account
                   ||'|'||l_def_include_in_rollup_flag
                   ||'|'||l_std_lot_size
                   ||'|'||l_eam_item_type
                   ||'|'||l_eam_activity_type_code
                   ||'|'||l_eam_activity_cause_code
                   ||'|'||l_eam_activity_source_code
                   ||'|'||l_eam_act_shutdown_status
                   ||'|'||l_eam_act_notification_flag
                   ||'|'||l_purchasing_item_flag
                   ||'|'||l_purchasing_enabled_flag
                   ||'|'||l_buyer_id
                   ||'|'||l_must_use_app_vendor_flag
                   ||'|'||l_purchasing_tax_code
                   ||'|'||l_taxable_flag
                   ||'|'||l_receive_close_tolerance
                   ||'|'||l_allow_item_desc_update_flag
                   ||'|'||l_inspection_required_flag
                   ||'|'||l_receipt_required_flag
                   ||'|'||l_market_price
                   ||'|'||l_un_number_id
                   ||'|'||l_hazard_class_id
                   ||'|'||l_rfq_required_flag
                   ||'|'||l_list_price_per_unit
                   ||'|'||l_price_tolerance_percent
                   ||'|'||l_asset_category_id
                   ||'|'||l_rounding_factor
                   ||'|'||l_unit_of_issue
                   ||'|'||l_outside_operation_flag
                   ||'|'||l_outside_operation_uom_type
                   ||'|'||l_invoice_close_tolerance
                   ||'|'||l_encumbrance_account
                   ||'|'||l_expense_account
                   ||'|'||l_outsourced_assembly
                   ||'|'||l_qty_rcv_exception_code
                   ||'|'||l_receiving_routing_id
                   ||'|'||l_qty_rcv_tolerance
                   ||'|'||l_enforce_ship_to_loc_code
                   ||'|'||l_allow_substitute_rec_flag
                   ||'|'||l_allow_unordered_rec_flag
                   ||'|'||l_allow_express_delivery_flag
                   ||'|'||l_days_early_receipt_allowed
                   ||'|'||l_days_late_receipt_allowed
                   ||'|'||l_receipt_days_exception_code
                   ||'|'||l_weight_uom_code
                   ||'|'||l_unit_weight
                   ||'|'||l_volume_uom_code
                   ||'|'||l_unit_volume
                   ||'|'||l_container_item_flag
                   ||'|'||l_vehicle_item_flag
                   ||'|'||l_maximum_load_weight
                   ||'|'||l_minimum_fill_percent
                   ||'|'||l_internal_volume
                   ||'|'||l_container_type_code
                   ||'|'||l_collateral_flag
                   ||'|'||l_equipment_type
                   ||'|'||l_indivisible_flag
                   ||'|'||l_dimension_uom_code
                   ||'|'||l_unit_length
                   ||'|'||l_unit_width
                   ||'|'||l_unit_height
                   ||'|'||l_inventory_planning_code
                   ||'|'||l_planner_code
                   ||'|'||l_planning_make_buy_code
                   ||'|'||l_min_minmax_quantity
                   ||'|'||l_max_minmax_quantity
                   ||'|'||l_safety_stock_bucket_days
                   ||'|'||l_carrying_cost
                   ||'|'||l_order_cost
                   ||'|'||l_mrp_safety_stock_percent
                   ||'|'||l_mrp_safety_stock_code
                   ||'|'||l_fixed_order_quantity
                   ||'|'||l_fixed_days_supply
                   ||'|'||l_minimum_order_quantity
                   ||'|'||l_maximum_order_quantity
                   ||'|'||l_fixed_lot_multiplier
                   ||'|'||l_source_type
                   ||'|'||l_source_organization_id
                   ||'|'||l_source_subinventory
                   ||'|'||l_vmi_minimum_units
                   ||'|'||l_vmi_minimum_days
                   ||'|'||l_vmi_maximum_units
                   ||'|'||l_vmi_maximum_days
                   ||'|'||l_vmi_fixed_order_quantity
                   ||'|'||l_so_authorization_flag
                   ||'|'||l_consigned_flag
                   ||'|'||l_vmi_forecast_type
                   ||'|'||l_forecast_horizon
                   ||'|'||l_asn_autoexpire_flag
                   ||'|'||l_subcontracting_component
                   ||'|'||l_mrp_planning_code
                   ||'|'||l_ato_forecast_control
                   ||'|'||l_planning_exception_set
                   ||'|'||l_shrinkage_rate
                   ||'|'||l_end_assembly_pegging_flag
                   ||'|'||l_rounding_control_type
                   ||'|'||l_planned_inv_point_flag
                   ||'|'||l_create_supply_flag
                   ||'|'||l_acceptable_early_days
                   ||'|'||l_critical_component_flag
                   ||'|'||l_exclude_from_budget_flag
                   ||'|'||l_mrp_calculate_atp_flag
                   ||'|'||l_auto_reduce_mps
                   ||'|'||l_repetitive_planning_flag
                   ||'|'||l_overrun_percentage
                   ||'|'||l_acceptable_rate_decrease
                   ||'|'||l_acceptable_rate_increase
                   ||'|'||l_planning_time_fence_code
                   ||'|'||l_planning_time_fence_days
                   ||'|'||l_demand_time_fence_code
                   ||'|'||l_demand_time_fence_days
                   ||'|'||l_release_time_fence_code
                   ||'|'||l_release_time_fence_days
                   ||'|'||l_substitution_window_code
                   ||'|'||l_substitution_window_days
                   ||'|'||l_drp_planned_flag
                   ||'|'||l_days_max_inv_supply
                   ||'|'||l_days_max_inv_window
                   ||'|'||l_days_tgt_inv_supply
                   ||'|'||l_days_tgt_inv_window
                   ||'|'||l_continous_transfer
                   ||'|'||l_convergence
                   ||'|'||l_divergence
                   ||'|'||l_repair_program
                   ||'|'||l_repair_leadtime
                   ||'|'||l_repair_yield
                   ||'|'||l_preposition_point
                   ||'|'||l_preprocessing_lead_time
                   ||'|'||l_full_lead_time
                   ||'|'||l_postprocessing_lead_time
                   ||'|'||l_fixed_lead_time
                   ||'|'||l_variable_lead_time
                   ||'|'||l_cum_manufacturing_lead_time
                   ||'|'||l_cumulative_total_lead_time
                   ||'|'||l_lead_time_lot_size
                   ||'|'||l_build_in_wip_flag
                   ||'|'||l_wip_supply_type
                   ||'|'||l_wip_supply_subinventory
                   ||'|'||l_wip_supply_locator_id
                   ||'|'||l_overcompletion_tol_type
                   ||'|'||l_overcompletion_tol_value
                   ||'|'||l_inventory_carry_penalty
                   ||'|'||l_operation_slack_penalty
                   ||'|'||l_customer_order_flag
                   ||'|'||l_customer_order_enabled_flag
                   ||'|'||l_internal_order_flag
                   ||'|'||l_internal_order_enabled_flag
                   ||'|'||l_shippable_item_flag
                   ||'|'||l_so_transactions_flag
                   ||'|'||l_picking_rule_id
                   ||'|'||l_pick_components_flag
                   ||'|'||l_replenish_to_order_flag
                   ||'|'||l_atp_flag
                   ||'|'||l_atp_components_flag
                   ||'|'||l_atp_rule_id
                   ||'|'||l_ship_model_complete_flag
                   ||'|'||l_default_shipping_org
                   ||'|'||l_default_so_source_type
                   ||'|'||l_returnable_flag
                   ||'|'||l_return_inspection_req
                   ||'|'||l_over_shipment_tolerance
                   ||'|'||l_under_shipment_tolerance
                   ||'|'||l_over_return_tolerance
                   ||'|'||l_under_return_tolerance
                   ||'|'||l_financing_allowed_flag
                   ||'|'||l_charge_periodicity_code
                   ||'|'||l_invoiceable_item_flag
                   ||'|'||l_invoice_enabled_flag
                   ||'|'||l_accounting_rule_id
                   ||'|'||l_invoicing_rule_id
                   ||'|'||l_tax_code
                   ||'|'||l_sales_account
                   ||'|'||l_payment_terms_id
                   ||'|'||l_contract_item_type_code
                   ||'|'||l_service_duration_period_code
                   ||'|'||l_service_duration
                   ||'|'||l_coverage_schedule_id
                   ||'|'||l_serv_req_enabled_code
                   ||'|'||l_serviceable_product_flag
                   ||'|'||l_material_billable_flag
                   ||'|'||l_serv_billing_enabled_flag
                   ||'|'||l_defect_tracking_on_flag
                   ||'|'||l_comms_nl_trackable_flag
                   ||'|'||l_asset_creation_code
                   ||'|'||l_ib_item_instance_class
                   ||'|'||l_service_starting_delay
                   ||'|'||l_web_status
                   ||'|'||l_orderable_on_web_flag
                   ||'|'||l_back_orderable_flag
                   ||'|'||l_minimum_license_quantity
                   ||'|'||l_recipe_enabled_flag
                   ||'|'||l_process_quality_enabled_flag
                   ||'|'||l_process_exec_enabled_flag
                   ||'|'||l_process_costing_enabled_flag
                   ||'|'||l_process_supply_subinventory
                   ||'|'||l_process_supply_locator_id
                   ||'|'||l_process_yield_subinventory
                   ||'|'||l_process_yield_locator_id
                   ||'|'||l_hazardous_material_flag
                   ||'|'||l_cas_number
                   ||'|'||l_serviceable_component_flag
                   ||'|'||l_descriptive_flexfield
                   ||'|'||l_max_warranty_amount
                   ||'|'||l_prorate_service_flag
                   ||'|'||l_base_warranty_service_id
                   ||'|'||l_engineering_date
                   ||'|'||l_new_revision_code
                   ||'|'||l_response_time_value
                   ||'|'||l_vol_discount_exempt_flag
                   ||'|'||l_serv_importance_level
                   ||'|'||l_response_time_period_code
                   ||'|'||l_vendor_warranty_flag
                   ||'|'||l_serviceable_item_class_id
                   ||'|'||l_event
                   ||'|'||l_coupon_exempt_flag
                   ||'|'||l_subscription_depend_flag
                   ||'|'||l_serial_tagging_flag
                   ||'|'||l_preventive_maintenance_flag
                   ||'|'||l_warranty_vendor_id
                   ||'|'||l_primary_specialist_id
                   ||'|'||l_usage_item_flag
                   ||'|'||l_recovered_part_disposition
                   ||'|'||l_downloadable
                   ||'|'||l_service_item_flag
                   ||'|'||l_secondary_specialist_id
                   ||'|'||l_electronic_format
                   ||'|'||l_long_description
                   ||'|'||l_dual_uom_control
                   ||'|'||l_primary_unit_of_measure
                   ||'|'||l_enable_provisioning
                   ||'|'||l_trade_item_descriptor

             INTO l_concat_output
             FROM (
                  SELECT  distinct_templates_rec.template_name template_name
                         ,distinct_templates_rec.description   description
                         ,template_id as template_id
                         ,NVL(UPPER(user_attribute_name),SUBSTR(attribute_name,18))  user_attribute_name
                         ,report_user_value
                  FROM mtl_item_templ_attributes_v mia
                 WHERE template_id = distinct_templates_rec.template_id

              )
              PIVOT
              (
                  MIN(report_user_value)
                  FOR user_attribute_name IN (
                                               'USER ITEM TYPE'                     AS    l_item_type,
                                               'ITEM STATUS'                        AS    l_inventory_item_status_code,
                                               'PRIMARY UNIT OF MEASURE'            AS    l_primary_uom_code,
                                               'CONVERSIONS'                        AS    l_allowed_units_lookup_code,
                                               'DESCRIPTION'                        AS    l_description,
                                               'GLOBAL DESCRIPTIVE FLEXFIELD'       AS    l_global_desc_flex,
                                               'TRACKING UOM INDICATOR'             AS    l_tracking_quantity_ind,
                                               'PRICING UOM INDICATOR'              AS    l_ont_pricing_qty_source,
                                               'DEFAULTING CONTROL'                 AS    l_secondary_default_ind,
                                               'SECONDARY UNIT OF MEASURE'          AS    l_secondary_uom_code,
                                               'DEVIATION FACTOR +'                 AS    l_dual_uom_deviation_high,
                                               'DEVIATION FACTOR -'                 AS    l_dual_uom_deviation_low,
                                               'INVENTORY ITEM'                     AS    l_inventory_item_flag,
                                               'STOCKABLE'                          AS    l_stock_enabled_flag,
                                               'TRANSACTABLE'                       AS    l_mtl_tran_enabled_flag,
                                               'REVISION CONTROL'                   AS    l_revision_qty_control_code,
                                               'LOT CONTROL'                        AS    l_lot_control_code,
                                               'STARTING LOT NUMBER'                AS    l_start_auto_lot_number,
                                               'STARTING LOT PREFIX'                AS    l_auto_lot_alpha_prefix,
                                               'SERIAL NUMBER GENERATION'           AS    l_serial_number_control_code,
                                               'STARTING SERIAL NUMBER'             AS    l_start_auto_serial_number,
                                               'STARTING SERIAL PREFIX'             AS    l_auto_serial_alpha_prefix,
                                               'LOT EXPIRATION'                     AS    l_shelf_life_code,
                                               'SHELF LIFE DAYS'                    AS    l_shelf_life_days,
                                               'RESTRICT SUBINVENTORIES'            AS    l_restrict_subinventories_code,
                                               'LOCATOR CONTROL'                    AS    l_location_control_code,
                                               'RESTRICT LOCATORS'                  AS    l_restrict_locators_code,
                                               'RESERVABLE'                         AS    l_reservable_type,
                                               'CYCLE COUNT ENABLED'                AS    l_cycle_count_enabled_flag,
                                               'NEGATIVE MEASUREMENT ERROR'         AS    l_negative_measurement_error,
                                               'POSITIVE MEASUREMENT ERROR'         AS    l_positive_measurement_error,
                                               'CHECK MATERIAL SHORTAGE'            AS    l_check_shortages_flag,
                                               'LOT STATUS ENABLED'                 AS    l_lot_status_enabled,
                                               'DEFAULT LOT STATUS'                 AS    l_default_lot_status_id,
                                               'SERIAL STATUS ENABLED'              AS    l_serial_status_enabled,
                                               'DEFAULT SERIAL STATUS'              AS    l_default_serial_status_id,
                                               'LOT SPLIT ENABLED'                  AS    l_lot_split_enabled,
                                               'LOT MERGE ENABLED'                  AS    l_lot_merge_enabled,
                                               'LOT TRANSLATE ENABLED'              AS    l_lot_translate_enabled,
                                               'LOT SUBSTITUTION ENABLED'           AS    l_lot_substitution_enabled,
                                               'BULK PICKED'                        AS    l_bulk_picked_flag,
                                               'LOT DIVISIBLE'                      AS    l_lot_divisible_flag,
                                               'GRADE CONTROLLED'                   AS    l_grade_control_flag,
                                               'DEFAULT GRADE'                      AS    l_default_grade,
                                               'CHILD LOT ENABLED'                  AS    l_child_lot_flag,
                                               'CHILD LOT GENERATION'               AS    l_parent_child_generation_flag,
                                               'CHILD LOT PREFIX'                   AS    l_child_lot_prefix,
                                               'CHILD LOT STARTING NUMBER'          AS    l_child_lot_starting_number,
                                               'CHILD LOT FORMAT VALIDATION'        AS    l_child_lot_validation_flag,
                                               'RETEST INTERVAL'                    AS    l_retest_interval,
                                               'EXPIRATION ACTION INTERVAL'         AS    l_expiration_action_interval,
                                               'EXPIRATION ACTION'                  AS    l_expiration_action_code,
                                               'MATURITY DAYS'                      AS    l_maturity_days,
                                               'HOLD DAYS'                          AS    l_hold_days,
                                               'COPY LOT ATTRIBUTES'                AS    l_copy_lot_attribute_flag,
                                               'BOM ITEM TYPE'                      AS    l_bom_item_type,
                                               'BOM ALLOWED'                        AS    l_bom_enabled_flag,
                                               'BASE MODEL'                         AS    l_base_item_id,
                                               'EFFECTIVITY CONTROL'                AS    l_effectivity_control,
                                               'AUTOCREATED CONFIGURATION'          AS    l_auto_created_config_flag,
                                               'CONFIGURATOR MODEL TYPE'            AS    l_config_model_type,
                                               'CREATE CONFIGURED ITEM, BOM'        AS    l_config_orgs,
                                               'MATCH CONFIGURATION'                AS    l_config_match,
                                               'COSTING ENABLED'                    AS    l_costing_enabled_flag,
                                               'INVENTORY ASSET VALUE'              AS    l_inventory_asset_flag,
                                               'COST OF GOODS SOLD ACCOUNT'         AS    l_cost_of_sales_account,
                                               'INCLUDE IN ROLLUP'                  AS    l_def_include_in_rollup_flag,
                                               'STANDARD LOT SIZE'                  AS    l_std_lot_size,
                                               'EAM ITEM TYPE'                      AS    l_eam_item_type,
                                               'EAM ACTIVITY TYPE'                  AS    l_eam_activity_type_code,
                                               'EAM ACTIVITY CAUSE'                 AS    l_eam_activity_cause_code,
                                               'EAM ACTIVITY SOURCE'                AS    l_eam_activity_source_code,
                                               'EAM SHUTDOWN TYPE'                  AS    l_eam_act_shutdown_status,
                                               'EAM NOTIFICATION REQUIRED'          AS    l_eam_act_notification_flag,
                                               'PURCHASED'                          AS    l_purchasing_item_flag,
                                               'PURCHASABLE'                        AS    l_purchasing_enabled_flag,
                                               'DEFAULT BUYER'                      AS    l_buyer_id,
                                               'USE APPROVED SUPPLIER'              AS    l_must_use_app_vendor_flag,
                                               'INPUT TAX CLASSIFICATION CODE'      AS    l_purchasing_tax_code,
                                               'TAXABLE'                            AS    l_taxable_flag,
                                               'RECEIPT CLOSE TOLERANCE'            AS    l_receive_close_tolerance,
                                               'ALLOW DESCRIPTION UPDATE'           AS    l_allow_item_desc_update_flag,
                                               'INSPECTION REQUIRED'                AS    l_inspection_required_flag,
                                               'RECEIPT REQUIRED'                   AS    l_receipt_required_flag,
                                               'MARKET PRICE'                       AS    l_market_price,
                                               'UN NUMBER'                          AS    l_un_number_id,
                                               'HAZARD CLASS'                       AS    l_hazard_class_id,
                                               'RFQ REQUIRED'                       AS    l_rfq_required_flag,
                                               'LIST PRICE'                         AS    l_list_price_per_unit,
                                               'PRICE TOLERANCE %'                  AS    l_price_tolerance_percent,
                                               'ASSET CATEGORY'                     AS    l_asset_category_id,
                                               'ROUNDING FACTOR'                    AS    l_rounding_factor,
                                               'UNIT OF ISSUE'                      AS    l_unit_of_issue,
                                               'OUTSIDE PROCESSING ITEM'            AS    l_outside_operation_flag,
                                               'OUTSIDE PROCESSING UNIT TYPE'       AS    l_outside_operation_uom_type,
                                               'INVOICE CLOSE TOLERANCE'            AS    l_invoice_close_tolerance,
                                               'ENCUMBRANCE ACCOUNT'                AS    l_encumbrance_account,
                                               'EXPENSE ACCOUNT'                    AS    l_expense_account,
                                               'OUTSOURCED ASSEMBLY'                AS    l_outsourced_assembly,
                                               'OVER-RECEIPT QTY ACTION'            AS    l_qty_rcv_exception_code,
                                               'RECEIPT ROUTING'                    AS    l_receiving_routing_id,
                                               'OVER-RECEIPT QTY TOLERANCE'         AS    l_qty_rcv_tolerance,
                                               'ENFORCE SHIP-TO'                    AS    l_enforce_ship_to_loc_code,
                                               'ALLOW SUBSTITUTE RECEIPTS'          AS    l_allow_substitute_rec_flag,
                                               'ALLOW UNORDERED RECEIPTS'           AS    l_allow_unordered_rec_flag,
                                               'ALLOW EXPRESS TRANSACTIONS'         AS    l_allow_express_delivery_flag,
                                               'DAYS EARLY RECEIPT ALLOWED'         AS    l_days_early_receipt_allowed,
                                               'DAYS LATE RECEIPT ALLOWED'          AS    l_days_late_receipt_allowed,
                                               'RECEIPT DATE ACTION'                AS    l_receipt_days_exception_code,
                                               'WEIGHT UNIT OF MEASURE'             AS    l_weight_uom_code,
                                               'UNIT WEIGHT'                        AS    l_unit_weight,
                                               'VOLUME UNIT OF MEASURE'             AS    l_volume_uom_code,
                                               'UNIT VOLUME'                        AS    l_unit_volume,
                                               'CONTAINER'                          AS    l_container_item_flag,
                                               'VEHICLE'                            AS    l_vehicle_item_flag,
                                               'MAXIMUM LOAD WEIGHT'                AS    l_maximum_load_weight,
                                               'MINIMUM FILL PERCENTAGE'            AS    l_minimum_fill_percent,
                                               'INTERNAL VOLUME'                    AS    l_internal_volume,
                                               'CONTAINER TYPE'                     AS    l_container_type_code,
                                               'COLLATERAL ITEM'                    AS    l_collateral_flag,
                                               'EQUIPMENT'                          AS    l_equipment_type,
                                               'OM INDIVISIBLE'                     AS    l_indivisible_flag,
                                               'DIMENSION UNIT OF MEASURE'          AS    l_dimension_uom_code,
                                               'LENGTH'                             AS    l_unit_length,
                                               'WIDTH'                              AS    l_unit_width,
                                               'HEIGHT'                             AS    l_unit_height,
                                               'INVENTORY PLANNING METHOD'          AS    l_inventory_planning_code,
                                               'PLANNER'                            AS    l_planner_code,
                                               'MAKE OR BUY'                        AS    l_planning_make_buy_code,
                                               'MIN-MAX MINIMUM QUANTITY'           AS    l_min_minmax_quantity,
                                               'MIN-MAX MAXIMUM QUANTITY'           AS    l_max_minmax_quantity,
                                               'SAFETY STOCK BUCKET DAYS'           AS    l_safety_stock_bucket_days,
                                               'CARRYING COST PERCENT'              AS    l_carrying_cost,
                                               'ORDER COST'                         AS    l_order_cost,
                                               'SAFETY STOCK PERCENT'               AS    l_mrp_safety_stock_percent,
                                               'SAFETY STOCK'                       AS    l_mrp_safety_stock_code,
                                               'FIXED ORDER QUANTITY'               AS    l_fixed_order_quantity,
                                               'FIXED DAYS SUPPLY'                  AS    l_fixed_days_supply,
                                               'MINIMUM ORDER QUANTITY'             AS    l_minimum_order_quantity,
                                               'MAXIMUM ORDER QUANTITY'             AS    l_maximum_order_quantity,
                                               'FIXED LOT SIZE MULTIPLIER'          AS    l_fixed_lot_multiplier,
                                               'SOURCE TYPE'                        AS    l_source_type,
                                               'SOURCE ORGANIZATION'                AS    l_source_organization_id,
                                               'SOURCE SUBINVENTORY'                AS    l_source_subinventory,
                                               'MINIMUM QUANTITY'                   AS    l_vmi_minimum_units,
                                               'MINIMUM DAYS OF SUPPLY'             AS    l_vmi_minimum_days,
                                               'MAXIMUM QUANTITY'                   AS    l_vmi_maximum_units,
                                               'MAXIMUM DAYS OF SUPPLY'             AS    l_vmi_maximum_days,
                                               'FIXED QUANTITY'                     AS    l_vmi_fixed_order_quantity,
                                               'RELEASE AUTHORIZATION REQUIRED'     AS    l_so_authorization_flag,
                                               'CONSIGNED'                          AS    l_consigned_flag,
                                               'FORECAST TYPE'                      AS    l_vmi_forecast_type,
                                               'WINDOW DAYS'                        AS    l_forecast_horizon,
                                               'AUTO-EXPIRE ASN'                    AS    l_asn_autoexpire_flag,
                                               'SUBCONTRACTING COMPONENT'           AS    l_subcontracting_component,
                                               'MRP PLANNING METHOD'                AS    l_mrp_planning_code,
                                               'FORECAST CONTROL'                   AS    l_ato_forecast_control,
                                               'PLANNING EXCEPTION SET'             AS    l_planning_exception_set,
                                               'SHRINKAGE RATE'                     AS    l_shrinkage_rate,
                                               'END ASSEMBLY PEGGING'               AS    l_end_assembly_pegging_flag,
                                               'ROUND ORDER QUANTITIES'             AS    l_rounding_control_type,
                                               'PLANNED INVENTORY POINT'            AS    l_planned_inv_point_flag,
                                               'CREATE SUPPLY'                      AS    l_create_supply_flag,
                                               'ACCEPTABLE EARLY DAYS'              AS    l_acceptable_early_days,
                                               'CRITICAL COMPONENT'                 AS    l_critical_component_flag,
                                               'EXCLUDE FROM BUDGET'                AS    l_exclude_from_budget_flag,
                                               'CALCULATE ATP'                      AS    l_mrp_calculate_atp_flag,
                                               'REDUCE MPS'                         AS    l_auto_reduce_mps,
                                               'REPETITIVE PLANNING'                AS    l_repetitive_planning_flag,
                                               'OVERRUN PERCENTAGE'                 AS    l_overrun_percentage,
                                               'ACCEPTABLE RATE -'                  AS    l_acceptable_rate_decrease,
                                               'ACCEPTABLE RATE +'                  AS    l_acceptable_rate_increase,
                                               'PLANNING TIME FENCE'                AS    l_planning_time_fence_code,
                                               'PLANNING TIME FENCE DAYS'           AS    l_planning_time_fence_days,
                                               'DEMAND TIME FENCE'                  AS    l_demand_time_fence_code,
                                               'DEMAND TIME FENCE DAYS'             AS    l_demand_time_fence_days,
                                               'RELEASE TIME FENCE'                 AS    l_release_time_fence_code,
                                               'RELEASE TIME FENCE DAYS'            AS    l_release_time_fence_days,
                                               'SUBSTITUTION WINDOW'                AS    l_substitution_window_code,
                                               'SUBSTITUTION WINDOW DAYS'           AS    l_substitution_window_days,
                                               'DRP PLANNED'                        AS    l_drp_planned_flag,
                                               'MAXIMUM INVENTORY DAYS SUPPLY'      AS    l_days_max_inv_supply,
                                               'MAXIMUM INVENTORY WINDOW'           AS    l_days_max_inv_window,
                                               'TARGET INVENTORY DAYS SUPPLY'       AS    l_days_tgt_inv_supply,
                                               'TARGET INVENTORY WINDOW'            AS    l_days_tgt_inv_window,
                                               'CONTINUOUS INTER ORG TRANSFERS'     AS    l_continous_transfer,
                                               'CONVERGENCE PATTERN'                AS    l_convergence,
                                               'DIVERGENCE PATTERN'                 AS    l_divergence,
                                               'REPAIR PROGRAM'                     AS    l_repair_program,
                                               'REPAIR LEAD-TIME'                   AS    l_repair_leadtime,
                                               'REPAIR YIELD'                       AS    l_repair_yield,
                                               'PRE-POSITIONING POINT'              AS    l_preposition_point,
                                               'PREPROCESSING LEAD TIME'            AS    l_preprocessing_lead_time,
                                               'PROCESSING LEAD TIME'               AS    l_full_lead_time,
                                               'POSTPROCESSING LEAD TIME'           AS    l_postprocessing_lead_time,
                                               'FIXED LEAD TIME'                    AS    l_fixed_lead_time,
                                               'VARIABLE LEAD TIME'                 AS    l_variable_lead_time,
                                               'CUM MANUFACTURING LEAD TIME'        AS    l_cum_manufacturing_lead_time,
                                               'CUMULATIVE TOTAL LEAD TIME'         AS    l_cumulative_total_lead_time,
                                               'LEAD TIME LOT SIZE'                 AS    l_lead_time_lot_size,
                                               'BUILD IN WIP'                       AS    l_build_in_wip_flag,
                                               'WIP SUPPLY TYPE'                    AS    l_wip_supply_type,
                                               'WIP SUPPLY SUBINVENTORY'            AS    l_wip_supply_subinventory,
                                               'WIP SUPPLY LOCATOR'                 AS    l_wip_supply_locator_id,
                                               'OVERCOMPLETION TOLERANCE TYPE'      AS    l_overcompletion_tol_type,
                                               'OVERCOMPLETION TOLERANCE VALUE'     AS    l_overcompletion_tol_value,
                                               'INVENTORY CARRY PENALTY'            AS    l_inventory_carry_penalty,
                                               'OPERATION SLACK PENALTY'            AS    l_operation_slack_penalty,
                                               'CUSTOMER ORDERED'                   AS    l_customer_order_flag,
                                               'CUSTOMER ORDERS ENABLED'            AS    l_customer_order_enabled_flag,
                                               'INTERNAL ORDERED'                   AS    l_internal_order_flag,
                                               'INTERNAL ORDERS ENABLED'            AS    l_internal_order_enabled_flag,
                                               'SHIPPABLE'                          AS    l_shippable_item_flag,
                                               'OE TRANSACTABLE'                    AS    l_so_transactions_flag,
                                               'PICKING RULE'                       AS    l_picking_rule_id,
                                               'PICK COMPONENTS'                    AS    l_pick_components_flag,
                                               'ASSEMBLE TO ORDER'                  AS    l_replenish_to_order_flag,
                                               'CHECK ATP'                          AS    l_atp_flag,
                                               'ATP COMPONENTS'                     AS    l_atp_components_flag,
                                               'ATP RULE'                           AS    l_atp_rule_id,
                                               'SHIP MODEL COMPLETE'                AS    l_ship_model_complete_flag,
                                               'DEFAULT SHIPPING ORGANIZATION'      AS    l_default_shipping_org,
                                               'DEFAULT SO SOURCE TYPE'             AS    l_default_so_source_type,
                                               'RETURNABLE'                         AS    l_returnable_flag,
                                               'RMA INSPECTION REQUIRED'            AS    l_return_inspection_req,
                                               'OVER SHIPMENT TOLERANCE'            AS    l_over_shipment_tolerance,
                                               'UNDER SHIPMENT TOLERANCE'           AS    l_under_shipment_tolerance,
                                               'OVER RETURN TOLERANCE'              AS    l_over_return_tolerance,
                                               'UNDER RETURN TOLERANCE'             AS    l_under_return_tolerance,
                                               'FINANCING ALLOWED'                  AS    l_financing_allowed_flag,
                                               'CHARGE PERIODICITY'                 AS    l_charge_periodicity_code,
                                               'INVOICEABLE ITEM'                   AS    l_invoiceable_item_flag,
                                               'INVOICE ENABLED'                    AS    l_invoice_enabled_flag,
                                               'ACCOUNTING RULE'                    AS    l_accounting_rule_id,
                                               'INVOICING RULE'                     AS    l_invoicing_rule_id,
                                               'OUTPUT TAX CLASSIFICATION CODE'     AS    l_tax_code,
                                               'SALES ACCOUNT'                      AS    l_sales_account,
                                               'PAYMENT TERMS'                      AS    l_payment_terms_id,
                                               'CONTRACT ITEM TYPE'                 AS    l_contract_item_type_code,
                                               'CONTRACT DURATION PERIOD'           AS    l_service_duration_period_code,
                                               'CONTRACT DURATION'                  AS    l_service_duration,
                                               'COVERAGE TEMPLATE'                  AS    l_coverage_schedule_id,
                                               'SERVICE REQUEST'                    AS    l_serv_req_enabled_code,
                                               'ENABLE CONTRACT COVERAGE'           AS    l_serviceable_product_flag,
                                               'BILLING TYPE'                       AS    l_material_billable_flag,
                                               'ENABLE SERVICE BILLING'             AS    l_serv_billing_enabled_flag,
                                               'ENABLE DEFECT TRACKING'             AS    l_defect_tracking_on_flag,
                                               'TRACK IN INSTALLED BASE'            AS    l_comms_nl_trackable_flag,
                                               'CREATE FIXED ASSET'                 AS    l_asset_creation_code,
                                               'ITEM INSTANCE CLASS'                AS    l_ib_item_instance_class,
                                               'STARTING DELAY (DAYS)'              AS    l_service_starting_delay,
                                               'WEB STATUS'                         AS    l_web_status,
                                               'ORDERABLE ON THE WEB'               AS    l_orderable_on_web_flag,
                                               'BACK ORDERABLE'                     AS    l_back_orderable_flag,
                                               'MINIMUM LICENSE QUANTITY'           AS    l_minimum_license_quantity,
                                               'RECIPE ENABLED'                     AS    l_recipe_enabled_flag,
                                               'PROCESS QUALITY ENABLED'            AS    l_process_quality_enabled_flag,
                                               'PROCESS EXECUTION ENABLED'          AS    l_process_exec_enabled_flag,
                                               'PROCESS COSTING ENABLED'            AS    l_process_costing_enabled_flag,
                                               'PROCESS SUPPLY SUBINVENTORY'        AS    l_process_supply_subinventory,
                                               'PROCESS SUPPLY LOCATOR'             AS    l_process_supply_locator_id,
                                               'PROCESS YIELD SUBINVENTORY'         AS    l_process_yield_subinventory,
                                               'PROCESS YIELD LOCATOR'              AS    l_process_yield_locator_id,
                                               'HAZARDOUS MATERIAL'                 AS    l_hazardous_material_flag,
                                               'CAS NUMBER'                         AS    l_cas_number       ,
                                               'SERVICEABLE_COMPONENT_FLAG'         AS    l_serviceable_component_flag,
                                               'DESCRIPTIVE FLEXFIELD'              AS    l_descriptive_flexfield,
                                               'MAX_WARRANTY_AMOUNT'                AS    l_max_warranty_amount,
                                               'PRORATE_SERVICE_FLAG'               AS    l_prorate_service_flag,
                                               'BASE_WARRANTY_SERVICE_ID'           AS    l_base_warranty_service_id,
                                               'ENGINEERING_DATE'                   AS    l_engineering_date,
                                               'NEW_REVISION_CODE'                  AS    l_new_revision_code,
                                               'RESPONSE_TIME_VALUE'                AS    l_response_time_value,
                                               'VOL_DISCOUNT_EXEMPT_FLAG'           AS    l_vol_discount_exempt_flag,
                                               'SERV_IMPORTANCE_LEVEL'              AS    l_serv_importance_level,
                                               'RESPONSE_TIME_PERIOD_CODE'          AS    l_response_time_period_code,
                                               'VENDOR_WARRANTY_FLAG'               AS    l_vendor_warranty_flag,
                                               'SERVICEABLE_ITEM_CLASS_ID'          AS    l_serviceable_item_class_id,
                                               'EVENT'                              AS    l_event,
                                               'COUPON_EXEMPT_FLAG'                 AS    l_coupon_exempt_flag,
                                               'SUBSCRIPTION_DEPEND_FLAG'           AS    l_subscription_depend_flag,
                                               'SERIAL_TAGGING_FLAG'                AS    l_serial_tagging_flag,
                                               'PREVENTIVE_MAINTENANCE_FLAG'        AS    l_preventive_maintenance_flag,
                                               'WARRANTY_VENDOR_ID'                 AS    l_warranty_vendor_id,
                                               'PRIMARY_SPECIALIST_ID'              AS    l_primary_specialist_id,
                                               'USAGE_ITEM_FLAG'                    AS    l_usage_item_flag,
                                               'RECOVERED PART DISPOSITION'         AS    l_recovered_part_disposition,
                                               'DOWNLOADABLE'                       AS    l_downloadable,
                                               'SERVICE_ITEM_FLAG'                  AS    l_service_item_flag,
                                               'SECONDARY_SPECIALIST_ID'            AS    l_secondary_specialist_id,
                                               'ELECTRONIC FORMAT'                  AS    l_electronic_format,
                                               'LONG DESCRIPTION'                   AS    l_long_description,
                                               'DUAL_UOM_CONTROL'                   AS    l_dual_uom_control,
                                               'PRIMARY_UNIT_OF_MEASURE'            AS    l_primary_unit_of_measure,
                                               'ENABLE PROVISIONING'                AS    l_enable_provisioning,
                                               'TRADE_ITEM_DESCRIPTOR'              AS    l_trade_item_descriptor
                                             )
                          )
             ;
         EXCEPTION
            WHEN OTHERS THEN
                l_errmsg := SQLERRM;
                fnd_file.put_line(fnd_file.log,'When others in printing template attributes :'||l_errmsg);
                errbuf  := l_errmsg;
                retcode := l_return_warning;
         END;
         fnd_file.put_line(fnd_file.output,l_concat_output);
      END LOOP;
      /*If no templates are found, print no data found*/
      IF l_template_exists = 'N' THEN
         fnd_file.put_line(fnd_file.output,'No Data Found');
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         l_errmsg := SQLERRM;
         fnd_file.put_line(fnd_file.log,'When others in procedure exection :'||l_errmsg);
         errbuf  := l_errmsg;
         retcode := l_return_failure;
   END generate_report;
END XXINTG_INV_ITEM_TEMP_PKG;
/
