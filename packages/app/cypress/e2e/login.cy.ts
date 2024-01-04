import login from '../fixtures/login.json';

describe('Login', () => {
  const NEXT_PUBLIC_SUPABASE_URL = Cypress.env('NEXT_PUBLIC_SUPABASE_URL');
  const APP_BASE_URL = Cypress.env('APP_BASE_URL');

  it('should successfully sign up', () => {
    cy.visit(`${APP_BASE_URL}/login`);

    const signUpLink = cy.get('a[href="/register"]').click();
    signUpLink.should('exist');

    cy.url({ timeout: 5000 }).should('include', '/register');

    const emailInput = cy.get('input[name="email"]').type(login.validEmail);
    emailInput.invoke('val').should('eq', login.validEmail);

    const passwordInput = cy.get('input[name="password"]').type(login.validPassword);
    passwordInput.should('have.value', login.validPassword).invoke('val').should('eq', login.validPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/signup?redirect_to*`).as('signUpApi');
    cy.get('button[type="submit"]').click();

    const api = cy.wait('@signUpApi');
    api.its('response.statusCode').should('eq', 200);
  });

  it('should successfully sign in with valid credentials', () => {
    cy.visit(`${APP_BASE_URL}/login`);

    const emailIn = cy.get('input[name="email"]').click();
    emailIn.type(login.validEmail).invoke('val').should('eq', login.validEmail);

    const passwordInput = cy.get('input[name="password"]').click();
    passwordInput.type(login.validPassword).invoke('val').should('eq', login.validPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token?grant_type=password`).as('loginApi');
    cy.get('button[type="submit"]').click();

    const api = cy.wait('@loginApi');
    api.then(() => {
      cy.url().should('include', '/dashboard');
    });
  });

  it('should fail sign in with inValid credentials', () => {
    cy.visit(`${APP_BASE_URL}/login`);

    const emailInput = cy.get('input[name="email"]').click();
    emailInput.type(login.validEmail).invoke('val').should('eq', login.validEmail);

    const passwordInput = cy.get('input[name="password"]').click();
    passwordInput.type(login.inValidPassword).invoke('val').should('eq', login.inValidPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token*`, () => {}).as('failedRequest');
    cy.get('button[type="submit"]').click();

    const api = cy.wait('@failedRequest');
    api.its('response.statusCode').should('eq', 400);

    cy.contains('Invalid login credentials').should('be.visible');
  });
});

export {};
