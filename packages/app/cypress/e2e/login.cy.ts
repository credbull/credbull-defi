import login from '../fixtures/login.json';

describe('Login', () => {
  const NEXT_PUBLIC_SUPABASE_URL = Cypress.env('NEXT_PUBLIC_SUPABASE_URL');
  const APP_BASE_URL = Cypress.env('APP_BASE_URL');

  const dom = {
    inputs: {
      email: () => cy.get('input[name="email"]'),
      password: () => cy.get('input[name="password"]'),
    },
    anchors: {
      register: () => cy.get('a[href="/register"]'),
    },
    buttons: {
      submit: () => cy.get('button[type="submit"]'),
    },
  };

  it('should successfully sign up', () => {
    cy.visit(`${APP_BASE_URL}/login`);

    dom.anchors.register().click();

    cy.url({ timeout: 5000 }).should('include', '/register');

    dom.inputs.email().type(login.validEmail);
    dom.inputs.email().invoke('val').should('eq', login.validEmail);

    dom.inputs.password().type(login.validPassword);
    dom.inputs.password().should('have.value', login.validPassword).invoke('val').should('eq', login.validPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/signup?redirect_to*`).as('signUpApi');
    dom.buttons.submit().click();

    cy.wait('@signUpApi');
    cy.get('@signUpApi').its('response.statusCode').should('eq', 200);
  });

  it('should successfully sign in with valid credentials', () => {
    cy.visit(`${APP_BASE_URL}/login`);

    dom.inputs.email().click();
    dom.inputs.email().type(login.validEmail).invoke('val').should('eq', login.validEmail);

    dom.inputs.password().click();
    dom.inputs.password().type(login.validPassword).invoke('val').should('eq', login.validPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token?grant_type=password`).as('loginApi');
    dom.buttons.submit().click();

    cy.wait('@loginApi');
    cy.get('@loginApi').then(() => {
      cy.url().should('include', '/dashboard');
    });
  });

  it('should fail sign in with inValid credentials', () => {
    cy.visit(`${APP_BASE_URL}/login`);

    dom.inputs.email().click();
    dom.inputs.email().type(login.validEmail).invoke('val').should('eq', login.validEmail);

    dom.inputs.password().click();
    dom.inputs.password().type(login.inValidPassword).invoke('val').should('eq', login.inValidPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token*`, () => {}).as('failedRequest');
    dom.buttons.submit().click();

    cy.wait('@failedRequest');
    cy.get('@failedRequest').its('response.statusCode').should('eq', 400);

    cy.contains('Invalid login credentials').should('be.visible');
  });
});

export {};
