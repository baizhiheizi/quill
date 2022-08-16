import { application } from '../javascript/controllers/application';

import ModalComponentController from './modal_component_controller';
application.register('modal-component', ModalComponentController);

import PreOrdersFormComponentController from './pre_orders/form_component_controller';
application.register('pre-orders-form-component', PreOrdersFormComponentController);

import PreOrdersPaymentComponentController from './pre_orders/payment_component_controller';
application.register('pre-orders-payment-component', PreOrdersPaymentComponentController);
