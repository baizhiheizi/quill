import { application } from '../javascript/controllers/application';

import ModalComponentController from './modal_component_controller';
application.register('modal-component', ModalComponentController);

import QrcodeComponentController from './qrcode_component_controller';
application.register('qrcode-component', QrcodeComponentController);

import TimeFormatComponentController from './time_format_component_controller';
application.register('time-format-component', TimeFormatComponentController);

import PreOrdersFormComponentController from './pre_orders/form_component_controller';
application.register('pre-orders-form-component', PreOrdersFormComponentController);

import PreOrdersPaymentComponentController from './pre_orders/payment_component_controller';
application.register('pre-orders-payment-component', PreOrdersPaymentComponentController);

import PreOrdersPayButtonComponentController from './pre_orders/pay_button_component_controller';
application.register('pre-orders-pay-button-component', PreOrdersPayButtonComponentController);

import PreOrdersStateComponentController from './pre_orders/state_component_controller';
application.register('pre-orders-state-component', PreOrdersStateComponentController);

import MvmPayButtonComponentController from './mvm_pay_button_component_controller';
application.register('mvm-pay-button-component', MvmPayButtonComponentController);