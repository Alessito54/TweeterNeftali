'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class User extends Model {
    static associate(models) {
      User.hasMany(models.Moto, { foreignKey: 'user_id' });
    }
  }
  
  User.init({
    username: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false
    },
    email: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false
    },
    name: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'User',
    tableName: 'users'
  });

  return User;
};
