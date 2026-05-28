module.exports = (sequelize, DataTypes) => {
  const Reaction = sequelize.define('Reaction', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    emoji: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        len: [1, 10]
      }
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
    createdAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    timestamps: false,
    tableName: 'reactions',
    indexes: [
      {
        unique: true,
        fields: ['tweetId', 'userId'],
        name: 'unique_user_reaction_per_tweet'
      }
    ]
  });

  Reaction.associate = (models) => {
    Reaction.belongsTo(models.Tweet, { foreignKey: 'tweetId' });
    Reaction.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return Reaction;
};
