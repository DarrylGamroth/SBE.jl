import baseline.*;
import org.agrona.concurrent.UnsafeBuffer;

import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.nio.file.Paths;

public class VerifyCarFixture
{
    public static void main(final String[] args) throws Exception
    {
        if (args.length < 1)
        {
            System.err.println("Usage: VerifyCarFixture <path>");
            System.exit(1);
            return;
        }

        final byte[] bytes = Files.readAllBytes(Paths.get(args[0]));
        final UnsafeBuffer buffer = new UnsafeBuffer(ByteBuffer.wrap(bytes));

        final MessageHeaderDecoder header = new MessageHeaderDecoder();
        final CarDecoder car = new CarDecoder();

        header.wrap(buffer, 0);
        car.wrapAndApplyHeader(buffer, 0, header);

        if (car.serialNumber() != 1234L)
        {
            throw new IllegalStateException("serialNumber mismatch");
        }
        if (car.modelYear() != 2013)
        {
            throw new IllegalStateException("modelYear mismatch");
        }
        if (car.available() != BooleanType.T)
        {
            throw new IllegalStateException("available mismatch");
        }
        if (car.code() != Model.A)
        {
            throw new IllegalStateException("code mismatch");
        }
        if (!"abcdef".equals(car.vehicleCode()))
        {
            throw new IllegalStateException("vehicleCode mismatch");
        }

        final OptionalExtrasDecoder extras = car.extras();
        if (!extras.cruiseControl() || !extras.sportsPack() || extras.sunRoof())
        {
            throw new IllegalStateException("extras mismatch");
        }

        final EngineDecoder engine = car.engine();
        if (engine.capacity() != 2000 || engine.numCylinders() != 4 || engine.boosterEnabled() != BooleanType.T)
        {
            throw new IllegalStateException("engine mismatch");
        }

        final CarDecoder.FuelFiguresDecoder fuelFigures = car.fuelFigures();
        while (fuelFigures.hasNext())
        {
            fuelFigures.next();
            fuelFigures.usageDescription();
        }

        final CarDecoder.PerformanceFiguresDecoder perfFigures = car.performanceFigures();
        while (perfFigures.hasNext())
        {
            perfFigures.next();
            final CarDecoder.PerformanceFiguresDecoder.AccelerationDecoder accel = perfFigures.acceleration();
            while (accel.hasNext())
            {
                accel.next();
                accel.seconds();
            }
        }

        if (!"Honda".equals(car.manufacturer()))
        {
            throw new IllegalStateException("manufacturer mismatch");
        }
        if (!"Civic VTi".equals(car.model()))
        {
            throw new IllegalStateException("model mismatch");
        }
        if (!"abcdef".equals(car.activationCode()))
        {
            throw new IllegalStateException("activationCode mismatch");
        }
    }
}
