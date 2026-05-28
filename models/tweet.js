module.exports = (sequelize, DataTypes) => {
  const Tweet = sequelize.define('Tweet', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    text: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    imageUrl: {
      type: DataTypes.STRING,
      allowNull: true
    },
    username: {
      type: DataTypes.STRING,
      allowNull: false
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    motoMarca: {
      type: DataTypes.STRING,
      allowNull: true
    },
    motoModelo: {
      type: DataTypes.STRING,
      allowNull: true
    },
    motoCilindrada: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    createdAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    timestamps: false,
    tableName: 'tweets'
  });

  Tweet.associate = (models) => {
    Tweet.belongsTo(models.User, { foreignKey: 'userId' });
    Tweet.hasMany(models.Reaction, { foreignKey: 'tweetId', onDelete: 'CASCADE' });
    Tweet.hasMany(models.Reply, { foreignKey: 'tweetId', onDelete: 'CASCADE' });
  };

  return Tweet;
};
