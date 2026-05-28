'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Moto extends Model {
    static associate(models) {
      Moto.belongsTo(models.User, { foreignKey: 'user_id' });
    }
  }
  
  Moto.init({
    marca: {
      type: DataTypes.STRING,
      allowNull: false
    },
    modelo: {
      type: DataTypes.STRING,
      allowNull: false
    },
    cilindrada: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    imagen_url: DataTypes.STRING,
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'Moto',
    tableName: 'motos'
  });

  return Moto;
};
