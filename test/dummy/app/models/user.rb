class User < ApplicationRecord
  include AgreementEngine::Signable
end
