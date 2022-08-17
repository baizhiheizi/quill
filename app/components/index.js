import { application } from '../javascript/controllers/application';

import ModalComponentController from './modal_component_controller';
application.register('modal-component', ModalComponentController);

import QrcodeComponentController from './qrcode_component_controller';
application.register('qrcode-component', QrcodeComponentController);

import PreOrdersFormComponentController from './pre_orders/form_component_controller';
application.register('pre-orders-form-component', PreOrdersFormComponentController);

import PreOrdersPaymentComponentController from './pre_orders/payment_component_controller';
application.register('pre-orders-payment-component', PreOrdersPaymentComponentController);

import PreOrdersButtonComponentController from './pre_orders/button_component_controller';
application.register('pre-orders-button-component', PreOrdersButtonComponentController);
