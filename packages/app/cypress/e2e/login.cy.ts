describe('Login', () => {
  it('should navigate to the login page', () => {
    cy.visit('http://localhost:3000/');

    cy.get('a[href*="login"]').click();

    cy.url().should('include', '/login');

    cy.get('h1').contains('Sign in');
  });
});

export {};
