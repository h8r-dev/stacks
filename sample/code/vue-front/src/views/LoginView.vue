<template>
  <div class="login">
    <a href="https://github.com/login/oauth/authorize?client_id=15349ed1aba701ddab30&redirect_uri=http://localhost:8000/github/oauth/redirect">Login with github account</a>
  </div>
</template>

<style>
.login a {
  font-size: 2rem;
}

@media (min-width: 1024px) {
  .login {
    min-height: 100vh;
    display: flex;
    align-items: center;
  }
}
</style>
