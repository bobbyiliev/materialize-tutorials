import { BaseModel, column } from '@ioc:Adonis/Lucid/Orm'

export default class Coordinate extends BaseModel {
  public static table = 'app.coordinates';
  @column({ isPrimary: true })
  public id: number

  @column() public user_id: number
  @column() public latitude: number
  @column() public longitude: number

}
