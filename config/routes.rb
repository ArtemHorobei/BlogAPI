Rails.application.routes.draw do
  devise_for :users

  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
      omniauth_callbacks: 'users/omniauth_callbacks',
      registrations:      'users/registrations',
      sessions:           'users/sessions',
      token_validations:  'users/token_validations',
      passwords:          'users/passwords'
  }

  devise_scope :user do
    post 'auth/keep_alive', to: 'users/sessions#keep_alive'
    post 'auth/sign_in_social/:provider', to: 'users/sessions#sign_in_social'
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
