module.exports = (sequelize, DataTypes) => {
  const Reply = sequelize.define('Reply', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    text: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    tweetId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'tweets',
        key: 'id'
      }
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    username: {
      type: DataTypes.STRING,
      allowNull: false
    },
    createdAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    timestamps: false,
    tableName: 'replies'
  });

  Reply.associate = (models) => {
    Reply.belongsTo(models.Tweet, { foreignKey: 'tweetId' });
    Reply.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return Reply;
};
