describe('Login', () => {
  const validEmail = 'shabhari@coducer.com';
  const validPassword = 'Password@123';
  const inValidPassword = 'Password@12312';
  const NEXT_PUBLIC_SUPABASE_URL = Cypress.env('NEXT_PUBLIC_SUPABASE_URL');

  it('should successfully sign up', () => {
    cy.visit('http://localhost:3000/login');

    cy.get('a.my-Text-root.my-Anchor-root.my-al7hm1').click().should('have.attr', 'href', '/register');

    cy.url({ timeout: 5000 }).should('include', '/register');

    cy.get('input[type="text"].my-Input-input.my-TextInput-input.my-1g14e8k[name="email"]')
      .as('emailInput')
      .click()
      .type(validEmail)
      .invoke('val')
      .should('eq', validEmail);

    cy.get('input[type="password"].my-13e8zn2.my-PasswordInput-innerInput[name="password"]')
      .as('passwordInput')
      .type(validPassword)
      .should('have.value', validPassword)
      .invoke('val')
      .should('eq', validPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/signup?redirect_to*`).as('signUpApi');

    cy.get('button.my-UnstyledButton-root.my-Button-root.my-t4tusc').click();
    cy.wait('@signUpApi').its('response.statusCode').should('eq', 200);
  });

  it('should successfully sign in with valid credentials', () => {
    cy.visit('http://localhost:3000/login');

    cy.get('#mantine-R3dbbb8llkq')
      // .should('be.visible', { timeout: 10000 })
      .click()
      .type(validEmail)
      .invoke('val')
      .should('eq', validEmail);

    cy.get('#mantine-R5dbbb8llkq')
      // .should('be.visible', { timeout: 10000 })
      .click()
      .type(validPassword)
      .invoke('val')
      .should('eq', validPassword);

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token?grant_type=password`).as('loginApi');
    cy.get('button.my-UnstyledButton-root.my-Button-root.my-t4tusc').click();

    cy.wait('@loginApi').then(() => {
      cy.url().should('include', '/dashboard');
    });
  });

  it('should fail sign in with inValid credentials', () => {
    cy.visit('http://localhost:3000/login');
    const invalidCredentialsErrorBody = { error: 'invalid_grant', error_description: 'Invalid login credentials' };

    cy.intercept('POST', `${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token*`, (req) => {}).as('failedRequest');
    cy.get('#mantine-R3dbbb8llkq')
      // .should('be.visible', { timeout: 10000 })
      .click()
      .type(validEmail)
      .invoke('val')
      .should('eq', validEmail);

    cy.get('#mantine-R5dbbb8llkq')
      // .should('be.visible', { timeout: 10000 })
      .click()
      .type(inValidPassword)
      .invoke('val')
      .should('eq', inValidPassword);

    cy.get('button.my-UnstyledButton-root.my-Button-root.my-t4tusc').click();

    cy.wait(1000);

    cy.wait('@failedRequest').its('response.statusCode').should('eq', 400);
    cy.contains('Invalid login credentials').should('be.visible');
  });

  // it('should sign in with discord', () => {
  //   cy.visit('http://localhost:3000/login');
  //   cy.url().should('include', '/login');
  //   const invalidCredentialsErrorBody = { error: 'invalid_grant', error_description: 'Invalid login credentials' };

  //   cy.contains('button.my-UnstyledButton-root.my-Button-root', 'Discord').should('exist').click();

  //   cy.wait(20000);
  //   // cy.location('href').should('include', 'discord.com/login?redirect_to=%2Foauth2%2Fauthorize');
  // });
});

export {};
