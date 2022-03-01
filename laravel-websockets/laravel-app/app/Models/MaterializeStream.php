<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MaterializeStream extends Model
{
    use HasFactory;

    protected $guarded = [];
    protected $connection = 'materialize';
    protected $table = 'materialize_stream';
    public $timestamps = false;

}
